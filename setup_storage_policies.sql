-- ============================================================================
-- SETUP STORAGE POLICIES FOR ALL BUCKETS
-- ============================================================================
-- This creates RLS policies to allow uploads and downloads for storage buckets
-- ============================================================================

-- Enable RLS on storage.objects (if not already enabled)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- POLICIES FOR product_images BUCKET
-- ============================================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow public uploads to product_images" ON storage.objects;
DROP POLICY IF EXISTS "Allow public downloads from product_images" ON storage.objects;
DROP POLICY IF EXISTS "Allow public deletes from product_images" ON storage.objects;

-- Policy 1: Allow anyone to upload to product_images
CREATE POLICY "Allow public uploads to product_images"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (bucket_id = 'product_images');

-- Policy 2: Allow anyone to view/download from product_images
CREATE POLICY "Allow public downloads from product_images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'product_images');

-- Policy 3: Allow anyone to delete from product_images
CREATE POLICY "Allow public deletes from product_images"
ON storage.objects
FOR DELETE
TO public
USING (bucket_id = 'product_images');

-- Policy 4: Allow anyone to update in product_images
CREATE POLICY "Allow public updates to product_images"
ON storage.objects
FOR UPDATE
TO public
USING (bucket_id = 'product_images')
WITH CHECK (bucket_id = 'product_images');

-- ============================================================================
-- POLICIES FOR user_media BUCKET
-- ============================================================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow public uploads to user_media" ON storage.objects;
DROP POLICY IF EXISTS "Allow public downloads from user_media" ON storage.objects;
DROP POLICY IF EXISTS "Allow public deletes from user_media" ON storage.objects;

-- Policy 1: Allow anyone to upload to user_media
CREATE POLICY "Allow public uploads to user_media"
ON storage.objects
FOR INSERT
TO public
WITH CHECK (bucket_id = 'user_media');

-- Policy 2: Allow anyone to view/download from user_media
CREATE POLICY "Allow public downloads from user_media"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'user_media');

-- Policy 3: Allow anyone to delete from user_media
CREATE POLICY "Allow public deletes from user_media"
ON storage.objects
FOR DELETE
TO public
USING (bucket_id = 'user_media');

-- Policy 4: Allow anyone to update in user_media
CREATE POLICY "Allow public updates to user_media"
ON storage.objects
FOR UPDATE
TO public
USING (bucket_id = 'user_media')
WITH CHECK (bucket_id = 'user_media');

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE '✅ STORAGE POLICIES CONFIGURED SUCCESSFULLY!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'Policies created for buckets:';
  RAISE NOTICE '  1. product_images - All operations allowed';
  RAISE NOTICE '  2. user_media - All operations allowed';
  RAISE NOTICE '';
  RAISE NOTICE 'Allowed operations:';
  RAISE NOTICE '  ✓ INSERT (upload files)';
  RAISE NOTICE '  ✓ SELECT (view/download files)';
  RAISE NOTICE '  ✓ UPDATE (replace files)';
  RAISE NOTICE '  ✓ DELETE (remove files)';
  RAISE NOTICE '';
  RAISE NOTICE 'Image uploads should now work! 🎉';
  RAISE NOTICE '============================================================================';
END $$;
