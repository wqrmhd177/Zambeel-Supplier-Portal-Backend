-- ============================================================================
-- ADD CATEGORY COLUMN TO USERS TABLE
-- ============================================================================
-- This adds the missing 'category' column for supplier category/type
-- ============================================================================

-- Add category column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS category TEXT;

-- Add comment
COMMENT ON COLUMN users.category IS 'Supplier product category (e.g., Electronics, Fashion, Home & Garden)';

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'CATEGORY COLUMN ADDED SUCCESSFULLY!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'The category column has been added to the users table.';
  RAISE NOTICE 'This stores the supplier product category.';
  RAISE NOTICE '============================================================================';
END $$;
