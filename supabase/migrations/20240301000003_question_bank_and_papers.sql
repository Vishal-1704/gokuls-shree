-- 20240301000003_question_bank_and_papers.sql
--
-- Replaces exam_categories/exam_questions as the source of truth for MCQ
-- authoring. Those two tables are left in place (nothing drops them) but the
-- app stops reading/writing them after this migration — existing authored
-- content is copied forward, not discarded.
--
-- Why a new table set instead of patching exam_categories/exam_questions:
-- the scheduling side of the exam feature (exam_schedules/exam_assignments)
-- was built against a `paper_sets` table that exam_categories doesn't match,
-- so paper authoring and scheduling were never actually connected. This
-- gives authoring a clean, correctly-named home; scheduling gets repointed
-- at it in a later migration.

CREATE TABLE IF NOT EXISTS public.question_bank (
  id              SERIAL PRIMARY KEY,
  course_id       INT REFERENCES public.courses(id),
  subject         TEXT,
  difficulty      TEXT DEFAULT 'medium' CHECK (difficulty IN ('easy', 'medium', 'hard')),
  question_text   TEXT NOT NULL,
  option_a        TEXT NOT NULL,
  option_b        TEXT NOT NULL,
  option_c        TEXT NOT NULL,
  option_d        TEXT NOT NULL,
  correct_option  SMALLINT NOT NULL CHECK (correct_option BETWEEN 1 AND 4),
  marks           NUMERIC(6,2) NOT NULL DEFAULT 1.0,
  status          SMALLINT NOT NULL DEFAULT 1,
  created_by      UUID REFERENCES public.profiles(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.papers (
  id                SERIAL PRIMARY KEY,
  title             TEXT NOT NULL,
  assessment_type   TEXT NOT NULL DEFAULT 'exam' CHECK (assessment_type IN ('test', 'exam')),
  branch_id         INT REFERENCES public.branches(id), -- NULL = all branches
  course_id         INT REFERENCES public.courses(id),
  total_marks       INT NOT NULL DEFAULT 100,
  pass_marks        INT NOT NULL DEFAULT 33,
  duration_minutes  INT NOT NULL DEFAULT 60,
  status            TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published')),
  created_by        UUID REFERENCES public.profiles(id),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.paper_questions (
  id            SERIAL PRIMARY KEY,
  paper_id      INT NOT NULL REFERENCES public.papers(id) ON DELETE CASCADE,
  question_id   INT NOT NULL REFERENCES public.question_bank(id) ON DELETE CASCADE,
  order_index   INT NOT NULL DEFAULT 0,
  UNIQUE (paper_id, question_id)
);

-- ── Carry forward existing authored content ─────────────────────────────────

INSERT INTO public.papers
  (id, title, branch_id, course_id, total_marks, pass_marks, duration_minutes, status, created_at)
SELECT
  ec.id, ec.name, ec.branch_id, ec.course_id, ec.total_marks, ec.pass_marks, ec.time_limit,
  CASE WHEN ec.status = 1 THEN 'published' ELSE 'draft' END,
  ec.created_at
FROM public.exam_categories ec
ON CONFLICT (id) DO NOTHING;

SELECT setval(
  pg_get_serial_sequence('public.papers', 'id'),
  COALESCE((SELECT MAX(id) FROM public.papers), 1)
);

INSERT INTO public.question_bank
  (id, course_id, question_text, option_a, option_b, option_c, option_d, correct_option, marks, status, created_at)
SELECT
  eq.id, ec.course_id, eq.question_text, eq.option_a, eq.option_b, eq.option_c, eq.option_d,
  eq.correct_option, eq.marks, eq.status, eq.created_at
FROM public.exam_questions eq
JOIN public.exam_categories ec ON ec.id = eq.category_id
ON CONFLICT (id) DO NOTHING;

SELECT setval(
  pg_get_serial_sequence('public.question_bank', 'id'),
  COALESCE((SELECT MAX(id) FROM public.question_bank), 1)
);

INSERT INTO public.paper_questions (paper_id, question_id, order_index)
SELECT eq.category_id, eq.id, eq.id
FROM public.exam_questions eq
ON CONFLICT (paper_id, question_id) DO NOTHING;
