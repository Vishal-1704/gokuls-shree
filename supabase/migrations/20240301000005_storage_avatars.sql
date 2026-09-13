-- ============================================================
-- Supabase Storage: Avatars Bucket and Row-Level Security Policies
-- Version: 1.0 | Date: 2026-09-12
-- ============================================================

-- 1. Create the 'avatars' storage bucket if it does not exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Ensure RLS is enabled on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Policy: Allow authenticated users to upload their avatar
DROP POLICY IF EXISTS "Allow authenticated users to upload avatars" ON storage.objects;
CREATE POLICY "Allow authenticated users to upload avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars');

-- 4. Policy: Allow authenticated users to update their avatar
DROP POLICY IF EXISTS "Allow authenticated users to update avatars" ON storage.objects;
CREATE POLICY "Allow authenticated users to update avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'avatars');

-- 5. Policy: Allow public read access to avatar photos
DROP POLICY IF EXISTS "Allow public to view avatars" ON storage.objects;
CREATE POLICY "Allow public to view avatars"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');
