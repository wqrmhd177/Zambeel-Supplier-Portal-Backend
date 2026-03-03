-- ============================================================================
-- SETUP STORAGE BUCKET FOR USER MEDIA (IMAGES)
-- ============================================================================
-- This creates the storage bucket and policies for uploading user images
-- ============================================================================

-- NOTE: Storage buckets are created via Supabase Dashboard or Storage API
-- This SQL file contains the policies to apply AFTER creating the bucket

-- ============================================================================
-- STORAGE BUCKET SETUP INSTRUCTIONS
-- ============================================================================
-- 1. Go to Supabase Dashboard → Storage
-- 2. Click "Create a new bucket"
-- 3. Bucket name: user_media
-- 4. Public bucket: YES (check the box)
-- 5. Click "Create bucket"
-- 
-- Then run the policies below in SQL Editor
-- ============================================================================

-- Create storage policies for user_media bucket
-- Policy 1: Allow public uploads (anyone can upload)
INSERT INTO storage.policies (name, bucket_id, definition)
VALUES (
  'Allow public uploads',
  'user_media',
  '(bucket_id = ''user_media'')'
)
ON CONFLICT (bucket_id, name) DO NOTHING;

-- Policy 2: Allow public reads (anyone can view/download)
INSERT INTO storage.policies (name, bucket_id, definition)
VALUES (
  'Allow public downloads',
  'user_media',
  '(bucket_id = ''user_media'')'
)
ON CONFLICT (bucket_id, name) DO NOTHING;

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'STORAGE POLICIES CONFIGURED!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'Make sure you have created the bucket first:';
  RAISE NOTICE '  1. Go to Supabase Dashboard → Storage';
  RAISE NOTICE '  2. Create bucket named: user_media';
  RAISE NOTICE '  3. Set as PUBLIC bucket';
  RAISE NOTICE '';
  RAISE NOTICE 'Policies applied:';
  RAISE NOTICE '  - Allow public uploads (anyone can upload)';
  RAISE NOTICE '  - Allow public downloads (anyone can view)';
  RAISE NOTICE '============================================================================';
END $$;
