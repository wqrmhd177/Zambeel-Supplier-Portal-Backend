-- Fix users table primary key to auto-generate UUIDs
-- This resolves the "duplicate key value violates unique constraint 'users_pkey'" error

-- Step 1: Check current primary key configuration
SELECT column_name, column_default, is_nullable
FROM information_schema.columns
WHERE table_name = 'users' AND column_name = 'id';

-- Step 2: Ensure id column has UUID default
ALTER TABLE users 
  ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- Step 3: Verify the fix
SELECT column_name, column_default, is_nullable
FROM information_schema.columns
WHERE table_name = 'users' AND column_name = 'id';

-- Step 4: Test by checking if there are any duplicate UUIDs
SELECT id, COUNT(*)
FROM users
GROUP BY id
HAVING COUNT(*) > 1;

-- Step 5: If you see duplicates, you may need to delete them manually
-- Run this ONLY if Step 4 shows duplicates:
-- DELETE FROM users WHERE id IN (
--   SELECT id FROM (
--     SELECT id, ROW_NUMBER() OVER(PARTITION BY id ORDER BY created_at DESC) as rn
--     FROM users
--   ) t WHERE rn > 1
-- );
