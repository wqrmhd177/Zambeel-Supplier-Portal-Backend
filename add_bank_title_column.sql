-- ============================================================================
-- ADD BANK_TITLE AND IBAN COLUMNS TO USERS TABLE
-- ============================================================================
-- This adds the missing 'bank_title' and 'iban' columns
-- Note: 'bank_account_title' exists but frontend uses 'bank_title'
--       'bank_account_number' exists but frontend uses 'iban'
-- ============================================================================

-- Add bank_title column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS bank_title TEXT;

-- Add iban column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS iban TEXT;

-- Add comments
COMMENT ON COLUMN users.bank_title IS 'Bank account title/holder name';
COMMENT ON COLUMN users.iban IS 'International Bank Account Number (IBAN)';

-- Copy data from old columns to new columns if they exist and new columns are empty
UPDATE users 
SET bank_title = bank_account_title 
WHERE bank_title IS NULL AND bank_account_title IS NOT NULL;

UPDATE users 
SET iban = bank_account_number 
WHERE iban IS NULL AND bank_account_number IS NOT NULL;

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'BANK_TITLE AND IBAN COLUMNS ADDED SUCCESSFULLY!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'The following columns have been added:';
  RAISE NOTICE '  - bank_title (Bank account holder name)';
  RAISE NOTICE '  - iban (International Bank Account Number)';
  RAISE NOTICE '';
  RAISE NOTICE 'Data has been copied from:';
  RAISE NOTICE '  - bank_account_title → bank_title';
  RAISE NOTICE '  - bank_account_number → iban';
  RAISE NOTICE '============================================================================';
END $$;
