-- ============================================================================
-- ADD ARCHIVED COLUMN TO USERS TABLE
-- ============================================================================
-- This adds the missing 'archived' column that the system is expecting
-- ============================================================================

-- Add archived column to users table (default false)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS archived BOOLEAN DEFAULT FALSE;

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_users_archived ON users(archived);

-- Add comment
COMMENT ON COLUMN users.archived IS 'Whether the user account is archived/deactivated';

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'ARCHIVED COLUMN ADDED SUCCESSFULLY!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'The archived column has been added to the users table.';
  RAISE NOTICE 'Default value: FALSE (users are active by default)';
  RAISE NOTICE '============================================================================';
END $$;
