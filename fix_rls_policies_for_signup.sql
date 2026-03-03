-- ============================================================================
-- FIX ROW LEVEL SECURITY POLICIES FOR USER SIGNUP
-- ============================================================================
-- This allows users to sign up (insert into users table)
-- ============================================================================

-- Enable RLS on users table (if not already enabled)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow public user registration" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;

-- Policy 1: Allow anyone to INSERT (signup/registration)
CREATE POLICY "Allow public user registration"
ON users
FOR INSERT
TO public
WITH CHECK (true);

-- Policy 2: Allow users to SELECT their own data
CREATE POLICY "Users can view own profile"
ON users
FOR SELECT
TO public
USING (
  user_id = current_setting('request.jwt.claims', true)::json->>'user_id'
  OR id::text = current_setting('request.jwt.claims', true)::json->>'sub'
);

-- Policy 3: Allow users to UPDATE their own data
CREATE POLICY "Users can update own profile"
ON users
FOR UPDATE
TO public
USING (
  user_id = current_setting('request.jwt.claims', true)::json->>'user_id'
  OR id::text = current_setting('request.jwt.claims', true)::json->>'sub'
)
WITH CHECK (
  user_id = current_setting('request.jwt.claims', true)::json->>'user_id'
  OR id::text = current_setting('request.jwt.claims', true)::json->>'sub'
);

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'RLS POLICIES CONFIGURED SUCCESSFULLY!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'Policies added:';
  RAISE NOTICE '  1. Allow public user registration (INSERT) - Anyone can sign up';
  RAISE NOTICE '  2. Users can view own profile (SELECT)';
  RAISE NOTICE '  3. Users can update own profile (UPDATE)';
  RAISE NOTICE '';
  RAISE NOTICE 'Users can now sign up without authentication!';
  RAISE NOTICE '============================================================================';
END $$;
