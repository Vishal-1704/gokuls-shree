-- ============================================================
-- Add 3 new courses, then delete every other course except the 8
-- currently in real use (from the GOKUL enrollment check) plus these 3 —
-- but ONLY where nothing anywhere actually references the course, so this
-- can never silently orphan real data or fail on a foreign-key violation.
-- Checked every table with a course_id FK in master_schema.sql: students,
-- subjects, fee_payments, admit_cards, marksheets, certificates.
-- ============================================================

INSERT INTO public.courses (name, branch_id, status)
VALUES
  ('Certificate in Hindi Typing', 1, 1),
  ('Certificate in English Typing', 1, 1),
  ('Certificate in Computer Awareness', 1, 1);

DELETE FROM public.courses c
WHERE c.id NOT IN (1, 26, 36, 50, 57, 61, 82, 96)
  AND c.name NOT IN ('Certificate in Hindi Typing', 'Certificate in English Typing', 'Certificate in Computer Awareness')
  AND NOT EXISTS (SELECT 1 FROM public.students s WHERE s.course_id = c.id)
  AND NOT EXISTS (SELECT 1 FROM public.subjects sub WHERE sub.course_id = c.id)
  AND NOT EXISTS (SELECT 1 FROM public.fee_payments f WHERE f.course_id = c.id)
  AND NOT EXISTS (SELECT 1 FROM public.admit_cards a WHERE a.course_id = c.id)
  AND NOT EXISTS (SELECT 1 FROM public.marksheets m WHERE m.course_id = c.id)
  AND NOT EXISTS (SELECT 1 FROM public.certificates cert WHERE cert.course_id = c.id);
