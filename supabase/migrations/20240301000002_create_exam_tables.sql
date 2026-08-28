-- ============================================================
-- Missing Exam Tables Definitions
-- ============================================================
-- The previous master_schema.sql missed creating these tables.
-- These CREATE TABLE IF NOT EXISTS statements are safe to run
-- without deleting any existing data.

CREATE TABLE IF NOT EXISTS public.paper_sets (
  id SERIAL PRIMARY KEY,
  name TEXT,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.exam_schedules (
  id SERIAL PRIMARY KEY,
  category_id INT REFERENCES public.paper_sets(id),
  name TEXT,
  status TEXT,
  publish_at TIMESTAMPTZ,
  start_at TIMESTAMPTZ,
  end_at TIMESTAMPTZ,
  time_limit INT,
  max_attempts INT DEFAULT 1,
  shuffle_questions BOOLEAN DEFAULT true,
  shuffle_options BOOLEAN DEFAULT true,
  negative_marking_enabled BOOLEAN DEFAULT false,
  marks_correct NUMERIC(10,2) DEFAULT 1.0,
  marks_wrong NUMERIC(10,2) DEFAULT 0.0,
  marks_unanswered NUMERIC(10,2) DEFAULT 0.0,
  negative_formula TEXT,
  created_by UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  assessment_type TEXT DEFAULT 'exam' CHECK (assessment_type IN ('test', 'exam'))
);

CREATE TABLE IF NOT EXISTS public.exam_assignments (
  id SERIAL PRIMARY KEY,
  exam_schedule_id INT REFERENCES public.exam_schedules(id) ON DELETE CASCADE,
  student_id UUID,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(exam_schedule_id, student_id)
);

CREATE TABLE IF NOT EXISTS public.exam_sessions (
  id SERIAL PRIMARY KEY,
  exam_schedule_id INT REFERENCES public.exam_schedules(id) ON DELETE CASCADE,
  student_id UUID,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  score NUMERIC(10,2),
  status TEXT DEFAULT 'in_progress'
);

CREATE TABLE IF NOT EXISTS public.questions (
  id SERIAL PRIMARY KEY,
  paper_set_id INT REFERENCES public.paper_sets(id) ON DELETE CASCADE,
  content TEXT,
  options JSONB,
  correct_option TEXT,
  marks NUMERIC(10,2) DEFAULT 1.0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.exam_answers (
  id SERIAL PRIMARY KEY,
  session_id INT REFERENCES public.exam_sessions(id) ON DELETE CASCADE,
  question_id INT REFERENCES public.questions(id) ON DELETE CASCADE,
  selected_option TEXT,
  is_correct BOOLEAN,
  marks_awarded NUMERIC(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.exam_results (
  id SERIAL PRIMARY KEY,
  exam_schedule_id INT REFERENCES public.exam_schedules(id) ON DELETE CASCADE,
  student_id UUID,
  total_score NUMERIC(10,2),
  passed BOOLEAN,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
