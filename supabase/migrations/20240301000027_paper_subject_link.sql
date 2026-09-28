-- Exam papers (paper_sets) currently link only to a course, with no way to
-- say which subject under that course the paper covers. subjects already
-- has real per-course data. Adds hierarchical Course -> Subject linking.
ALTER TABLE public.paper_sets
  ADD COLUMN IF NOT EXISTS subject_id INT REFERENCES public.subjects(id);

CREATE INDEX IF NOT EXISTS idx_paper_sets_subject ON public.paper_sets(subject_id);
