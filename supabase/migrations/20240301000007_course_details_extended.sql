-- ============================================================
-- Migration: 20240301000007_course_details_extended.sql
-- Extend courses table with Coursera-style dynamic course fields
-- ============================================================

ALTER TABLE public.courses
  ADD COLUMN IF NOT EXISTS eligibility TEXT DEFAULT '10th / 12th Pass from recognized board',
  ADD COLUMN IF NOT EXISTS total_classes INT DEFAULT 120,
  ADD COLUMN IF NOT EXISTS theory_marks INT DEFAULT 60,
  ADD COLUMN IF NOT EXISTS practical_marks INT DEFAULT 30,
  ADD COLUMN IF NOT EXISTS internal_marks INT DEFAULT 10,
  ADD COLUMN IF NOT EXISTS syllabus JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS career_opportunities JSONB DEFAULT '[]'::jsonb;

COMMENT ON COLUMN public.courses.eligibility IS 'Minimum educational or prerequisite qualification required';
COMMENT ON COLUMN public.courses.total_classes IS 'Total sessions / lectures in the course program';
COMMENT ON COLUMN public.courses.theory_marks IS 'Theory written examination marks weightage';
COMMENT ON COLUMN public.courses.practical_marks IS 'Lab practical and viva examination marks weightage';
COMMENT ON COLUMN public.courses.internal_marks IS 'Internal assignments and attendance evaluation weightage';
COMMENT ON COLUMN public.courses.syllabus IS 'Array of syllabus modules with title and topics: [{"title": "...", "topics": "..."}]';
COMMENT ON COLUMN public.courses.career_opportunities IS 'Array of career job roles and employment prospects';
