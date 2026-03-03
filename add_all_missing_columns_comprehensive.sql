-- ============================================================================
-- COMPREHENSIVE: ADD ALL MISSING COLUMNS TO USERS TABLE
-- ============================================================================
-- Run this to add ALL columns that might be missing from the users table
-- This prevents repeated "column not found" errors
-- ============================================================================

-- Add all columns with IF NOT EXISTS (safe to run multiple times)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS user_id TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS archived BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS account_approval TEXT DEFAULT 'Wait',
ADD COLUMN IF NOT EXISTS bank_title TEXT,
ADD COLUMN IF NOT EXISTS iban TEXT,
ADD COLUMN IF NOT EXISTS binance_wallet TEXT,
ADD COLUMN IF NOT EXISTS paypal_email TEXT,
ADD COLUMN IF NOT EXISTS paypal_account_name TEXT,
ADD COLUMN IF NOT EXISTS exchange_name TEXT,
ADD COLUMN IF NOT EXISTS exchange_account_name TEXT,
ADD COLUMN IF NOT EXISTS exchange_id TEXT,
ADD COLUMN IF NOT EXISTS exchange_country TEXT,
ADD COLUMN IF NOT EXISTS payment_method TEXT,
ADD COLUMN IF NOT EXISTS cnic TEXT,
ADD COLUMN IF NOT EXISTS pickup_address TEXT,
ADD COLUMN IF NOT EXISTS return_address TEXT,
ADD COLUMN IF NOT EXISTS return_city TEXT,
ADD COLUMN IF NOT EXISTS whatsapp_phone_number TEXT,
ADD COLUMN IF NOT EXISTS supplier_type TEXT,
ADD COLUMN IF NOT EXISTS shop_name TEXT,
ADD COLUMN IF NOT EXISTS stock_location_country TEXT,
ADD COLUMN IF NOT EXISTS category TEXT,
ADD COLUMN IF NOT EXISTS user_picture_url TEXT,
ADD COLUMN IF NOT EXISTS store_picture_url TEXT;

-- Add constraint for account_approval if not exists
DO $$ 
BEGIN
    ALTER TABLE users
    ADD CONSTRAINT check_account_approval_valid 
    CHECK (account_approval IN ('Wait', 'Approved', 'Rejected'));
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_archived ON users(archived);
CREATE INDEX IF NOT EXISTS idx_users_account_approval ON users(account_approval);

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'COMPREHENSIVE COLUMN MIGRATION COMPLETE!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'All missing columns have been added to the users table.';
  RAISE NOTICE 'Your signup/onboarding should now work completely!';
  RAISE NOTICE '============================================================================';
END $$;
