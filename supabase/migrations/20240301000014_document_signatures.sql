-- 20240301000014_document_signatures.sql
--
-- Adds real tamper detection to marksheet/certificate QR verification.
-- Before this migration, "verification" (verification_screen.dart /
-- document_repository.getDocumentById) only checked whether a row with a
-- given id existed and had status=1 — it never checked whether the row's
-- actual data still matched what was originally approved. Anyone who
-- edited marks/names directly in the database after approval (or via any
-- future bug in an admin screen) would still show as "Valid" to a QR scan.
--
-- Fix: every marksheet/certificate gets an HMAC-SHA256 signature over its
-- own key fields, computed server-side with a secret the client never
-- sees. A trigger computes it the moment status transitions to 1
-- (approved) — not just when the approval RPC is used — so there is no
-- direct-UPDATE path that can approve a document without also signing it.
-- Verification recomputes the same HMAC from the CURRENT row and compares:
-- match -> valid, mismatch -> tampered, no row -> not_found.
--
-- The secret is stored in Supabase Vault, not a database-level GUC setting
-- (`ALTER DATABASE ... SET ...` requires superuser, which the Supabase SQL
-- editor role does not have — this migration originally tried that and
-- failed with "permission denied to set parameter"). Vault is the
-- Supabase-native way to hold a server-only secret: it's an encrypted
-- table (vault.secrets) readable in decrypted form only via
-- vault.decrypted_secrets, which itself is only queried from inside
-- SECURITY DEFINER function bodies below — never exposed to any client.

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS supabase_vault;

ALTER TABLE public.marksheets   ADD COLUMN IF NOT EXISTS signature_hash TEXT;
ALTER TABLE public.certificates ADD COLUMN IF NOT EXISTS signature_hash TEXT;

-- Seed the secret once. If it already exists (re-running this migration),
-- leave it untouched rather than rotating it, which would invalidate
-- every signature already issued.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM vault.secrets WHERE name = 'doc_signing_secret') THEN
    PERFORM vault.create_secret(encode(gen_random_bytes(32), 'hex'), 'doc_signing_secret');
  END IF;
END $$;

-- ── Reads the secret from Vault. Only ever called from inside another
-- SECURITY DEFINER function below — never granted to anon/authenticated
-- directly, so a client can never read the secret itself.
CREATE OR REPLACE FUNCTION public._doc_signing_secret()
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'doc_signing_secret';
$$;

-- ── Canonical string of the fields that must not silently change post-
-- approval. Order and format are fixed forever once documents are signed
-- with it — changing this function invalidates every existing signature.
CREATE OR REPLACE FUNCTION public._marksheet_signing_payload(p_id INT)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT concat_ws('|',
    m.id, m.student_id, m.course_id, m.roll_no, m.session,
    m.marks::text, m.total_marks, m.obtained_marks, m.percentage,
    m.grade, m.result
  )
  FROM public.marksheets m WHERE m.id = p_id;
$$;

CREATE OR REPLACE FUNCTION public._certificate_signing_payload(p_id INT)
RETURNS TEXT
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT concat_ws('|',
    c.id, c.student_id, c.course_id, c.certificate_no, c.session, c.issue_date
  )
  FROM public.certificates c WHERE c.id = p_id;
$$;

-- ── Trigger: sign automatically the moment status becomes 1, from ANY
-- update path (RPC or direct client UPDATE, since RLS already restricts
-- who can update these tables to super_admin). ──────────────────────────
CREATE OR REPLACE FUNCTION public._sign_marksheet_on_approve()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.status = 1 AND (OLD.status IS DISTINCT FROM 1 OR NEW.signature_hash IS NULL) THEN
    NEW.signature_hash := encode(
      hmac(
        public._marksheet_signing_payload(NEW.id),
        public._doc_signing_secret(),
        'sha256'
      ),
      'hex'
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sign_marksheet ON public.marksheets;
CREATE TRIGGER trg_sign_marksheet
  BEFORE UPDATE ON public.marksheets
  FOR EACH ROW
  EXECUTE FUNCTION public._sign_marksheet_on_approve();

CREATE OR REPLACE FUNCTION public._sign_certificate_on_approve()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.status = 1 AND (OLD.status IS DISTINCT FROM 1 OR NEW.signature_hash IS NULL) THEN
    NEW.signature_hash := encode(
      hmac(
        public._certificate_signing_payload(NEW.id),
        public._doc_signing_secret(),
        'sha256'
      ),
      'hex'
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_sign_certificate ON public.certificates;
CREATE TRIGGER trg_sign_certificate
  BEFORE UPDATE ON public.certificates
  FOR EACH ROW
  EXECUTE FUNCTION public._sign_certificate_on_approve();

-- ── Public verification RPC — recomputes the HMAC from the document's
-- CURRENT data and compares to what was stored at approval time. ────────
CREATE OR REPLACE FUNCTION public.verify_document_signature(p_type TEXT, p_id INT)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_stored_hash TEXT;
  v_status      SMALLINT;
  v_expected    TEXT;
BEGIN
  IF p_type = 'marksheet' THEN
    SELECT signature_hash, status INTO v_stored_hash, v_status
    FROM public.marksheets WHERE id = p_id;
  ELSIF p_type = 'certificate' THEN
    SELECT signature_hash, status INTO v_stored_hash, v_status
    FROM public.certificates WHERE id = p_id;
  ELSE
    RETURN json_build_object('result', 'not_found');
  END IF;

  IF NOT FOUND OR v_status IS NULL THEN
    RETURN json_build_object('result', 'not_found');
  END IF;

  IF v_status != 1 OR v_stored_hash IS NULL THEN
    -- Exists but was never approved/signed (still pending, or predates
    -- this migration and hasn't been re-approved since).
    RETURN json_build_object('result', 'unsigned');
  END IF;

  v_expected := encode(
    hmac(
      CASE p_type
        WHEN 'marksheet' THEN public._marksheet_signing_payload(p_id)
        ELSE public._certificate_signing_payload(p_id)
      END,
      public._doc_signing_secret(),
      'sha256'
    ),
    'hex'
  );

  IF v_expected = v_stored_hash THEN
    RETURN json_build_object('result', 'valid');
  ELSE
    RETURN json_build_object('result', 'tampered');
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.verify_document_signature(TEXT, INT) TO anon, authenticated;

-- ── Sign every already-approved document that predates this migration,
-- so existing marksheets/certificates aren't stuck showing "unsigned". ──
UPDATE public.marksheets
SET signature_hash = encode(hmac(public._marksheet_signing_payload(id), public._doc_signing_secret(), 'sha256'), 'hex')
WHERE status = 1 AND signature_hash IS NULL;

UPDATE public.certificates
SET signature_hash = encode(hmac(public._certificate_signing_payload(id), public._doc_signing_secret(), 'sha256'), 'hex')
WHERE status = 1 AND signature_hash IS NULL;
