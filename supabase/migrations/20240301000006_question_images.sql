-- ============================================================
-- Question images: lets a question carry a diagram/image (e.g. a circuit
-- diagram, a graph) alongside its text. Same bucket/policy shape as
-- 20240301000005_storage_avatars.sql.
-- ============================================================

ALTER TABLE public.question_bank ADD COLUMN IF NOT EXISTS image_url TEXT;

INSERT INTO storage.buckets (id, name, public)
VALUES ('question-images', 'question-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow authenticated users to upload question images" ON storage.objects;
CREATE POLICY "Allow authenticated users to upload question images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'question-images');

DROP POLICY IF EXISTS "Allow authenticated users to update question images" ON storage.objects;
CREATE POLICY "Allow authenticated users to update question images"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'question-images');

DROP POLICY IF EXISTS "Allow authenticated users to delete question images" ON storage.objects;
CREATE POLICY "Allow authenticated users to delete question images"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'question-images');

DROP POLICY IF EXISTS "Allow public to view question images" ON storage.objects;
CREATE POLICY "Allow public to view question images"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'question-images');
