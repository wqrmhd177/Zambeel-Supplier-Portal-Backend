-- ============================================================================
-- ADD ACCOUNT_APPROVAL COLUMN TO USERS TABLE
-- ============================================================================
-- This adds the missing 'account_approval' column that the system is expecting
-- ============================================================================

-- Add account_approval column to users table (default 'Wait')
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS account_approval TEXT DEFAULT 'Wait';

-- Add check constraint to ensure valid values
ALTER TABLE users
DROP CONSTRAINT IF EXISTS check_account_approval_valid;

ALTER TABLE users
ADD CONSTRAINT check_account_approval_valid 
CHECK (account_approval IN ('Wait', 'Approved', 'Rejected'));

-- Add index for better query performance
CREATE INDEX IF NOT EXISTS idx_users_account_approval ON users(account_approval);

-- Add comment
COMMENT ON COLUMN users.account_approval IS 'Account approval status: Wait, Approved, or Rejected';

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'ACCOUNT_APPROVAL COLUMN ADDED SUCCESSFULLY!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'The account_approval column has been added to the users table.';
  RAISE NOTICE 'Default value: Wait (pending approval)';
  RAISE NOTICE 'Allowed values: Wait, Approved, Rejected';
  RAISE NOTICE '============================================================================';
END $$;
