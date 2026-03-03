-- ============================================================================
-- DISABLE RLS OR CREATE PERMISSIVE POLICY FOR USERS TABLE
-- ============================================================================
-- Your app uses custom auth (not Supabase Auth), so we need permissive RLS
-- ============================================================================

-- OPTION 1: Disable RLS completely (simplest for custom auth)
-- Uncomment this line if you want to disable RLS:
-- ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- OPTION 2: Enable RLS but make it fully permissive (recommended)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "Allow public user registration" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Enable all access for users" ON users;

-- Create a single permissive policy that allows all operations
CREATE POLICY "Enable all access for users"
ON users
FOR ALL
TO public
USING (true)
WITH CHECK (true);

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'RLS POLICY UPDATED - FULLY PERMISSIVE!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'All operations (SELECT, INSERT, UPDATE, DELETE) are now allowed.';
  RAISE NOTICE 'This is appropriate for custom authentication systems.';
  RAISE NOTICE '';
  RAISE NOTICE 'Note: If you need more security later, implement policies that match';
  RAISE NOTICE 'your custom authentication logic.';
  RAISE NOTICE '============================================================================';
END $$;
