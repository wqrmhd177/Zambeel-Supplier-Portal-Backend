-- Fix users table: Change id from INTEGER to UUID
-- This resolves the signup error

-- Step 1: Check current structure
SELECT 
  column_name, 
  data_type, 
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'users' 
  AND column_name IN ('id', 'user_id')
ORDER BY column_name;

-- Step 2: Create a new UUID column temporarily
ALTER TABLE users ADD COLUMN id_new UUID DEFAULT gen_random_uuid();

-- Step 3: Populate the new column with UUIDs for existing rows
UPDATE users SET id_new = gen_random_uuid() WHERE id_new IS NULL;

-- Step 4: Drop the primary key constraint on old id
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_pkey;

-- Step 5: Drop the old integer id column
ALTER TABLE users DROP COLUMN id;

-- Step 6: Rename the new column to id
ALTER TABLE users RENAME COLUMN id_new TO id;

-- Step 7: Set id as NOT NULL
ALTER TABLE users ALTER COLUMN id SET NOT NULL;

-- Step 8: Add primary key constraint back
ALTER TABLE users ADD PRIMARY KEY (id);

-- Step 9: Verify the fix
SELECT 
  column_name, 
  data_type, 
  column_default,
  is_nullable
FROM information_schema.columns
WHERE table_name = 'users' 
  AND column_name IN ('id', 'user_id')
ORDER BY column_name;

-- Step 10: Check the data
SELECT id, user_id, email, role, created_at
FROM users
ORDER BY created_at DESC
LIMIT 5;
