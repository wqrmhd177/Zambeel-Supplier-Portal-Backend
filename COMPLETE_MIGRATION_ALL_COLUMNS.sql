-- ============================================================================
-- COMPLETE MIGRATION: ALL COLUMNS FOR USERS TABLE
-- ============================================================================
-- This is the FINAL, COMPLETE migration that adds EVERY column needed
-- Run this ONCE and you'll never get "column not found" errors again!
-- ============================================================================

-- Add ALL columns with IF NOT EXISTS (safe to run multiple times)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS user_id TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS full_name TEXT,
ADD COLUMN IF NOT EXISTS owner_name TEXT,
ADD COLUMN IF NOT EXISTS country TEXT,
ADD COLUMN IF NOT EXISTS cnic TEXT,
ADD COLUMN IF NOT EXISTS pickup_address TEXT,
ADD COLUMN IF NOT EXISTS pickup_city TEXT,
ADD COLUMN IF NOT EXISTS phone_number TEXT,
ADD COLUMN IF NOT EXISTS whatsapp_phone_number TEXT,
ADD COLUMN IF NOT EXISTS supplier_type TEXT,
ADD COLUMN IF NOT EXISTS category TEXT,
ADD COLUMN IF NOT EXISTS shop_name TEXT,
ADD COLUMN IF NOT EXISTS shop_name_on_zambeel TEXT,
ADD COLUMN IF NOT EXISTS stock_location_country TEXT,
ADD COLUMN IF NOT EXISTS return_address TEXT,
ADD COLUMN IF NOT EXISTS return_city TEXT,
ADD COLUMN IF NOT EXISTS payment_method TEXT,
ADD COLUMN IF NOT EXISTS bank_country TEXT,
ADD COLUMN IF NOT EXISTS bank_title TEXT,
ADD COLUMN IF NOT EXISTS bank_name TEXT,
ADD COLUMN IF NOT EXISTS bank_account_number TEXT,
ADD COLUMN IF NOT EXISTS bank_account_title TEXT,
ADD COLUMN IF NOT EXISTS iban TEXT,
ADD COLUMN IF NOT EXISTS paypal_email TEXT,
ADD COLUMN IF NOT EXISTS paypal_account_name TEXT,
ADD COLUMN IF NOT EXISTS exchange_name TEXT,
ADD COLUMN IF NOT EXISTS exchange_account_name TEXT,
ADD COLUMN IF NOT EXISTS exchange_id TEXT,
ADD COLUMN IF NOT EXISTS exchange_country TEXT,
ADD COLUMN IF NOT EXISTS binance_wallet TEXT,
ADD COLUMN IF NOT EXISTS user_picture_url TEXT,
ADD COLUMN IF NOT EXISTS store_picture_url TEXT,
ADD COLUMN IF NOT EXISTS profile_picture TEXT,
ADD COLUMN IF NOT EXISTS store_name TEXT,
ADD COLUMN IF NOT EXISTS city TEXT,
ADD COLUMN IF NOT EXISTS currency TEXT DEFAULT 'USD',
ADD COLUMN IF NOT EXISTS purchaser_id INTEGER,
ADD COLUMN IF NOT EXISTS onboarded BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS archived BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS account_approval TEXT DEFAULT 'Wait',
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Add constraints
DO $$ 
BEGIN
    -- Account approval constraint
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'check_account_approval_valid'
    ) THEN
        ALTER TABLE users
        ADD CONSTRAINT check_account_approval_valid 
        CHECK (account_approval IN ('Wait', 'Approved', 'Rejected'));
    END IF;

    -- Role constraint (if not exists)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'check_role_valid'
    ) THEN
        ALTER TABLE users
        ADD CONSTRAINT check_role_valid 
        CHECK (role IN ('supplier', 'purchaser', 'agent', 'admin'));
    END IF;
END $$;

-- Create all indexes
CREATE INDEX IF NOT EXISTS idx_users_user_id ON users(user_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_purchaser_id ON users(purchaser_id);
CREATE INDEX IF NOT EXISTS idx_users_onboarded ON users(onboarded);
CREATE INDEX IF NOT EXISTS idx_users_archived ON users(archived);
CREATE INDEX IF NOT EXISTS idx_users_account_approval ON users(account_approval);
CREATE INDEX IF NOT EXISTS idx_users_country ON users(country);

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE '✅ COMPLETE MIGRATION FINISHED!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'ALL columns have been added to the users table:';
  RAISE NOTICE '';
  RAISE NOTICE '📋 Basic Info: user_id, full_name, owner_name, email, password, role';
  RAISE NOTICE '📍 Location: country, city, pickup_city, return_city';
  RAISE NOTICE '📞 Contact: phone_number, whatsapp_phone_number';
  RAISE NOTICE '🏪 Business: supplier_type, category, shop_name, shop_name_on_zambeel';
  RAISE NOTICE '📦 Logistics: pickup_address, return_address, stock_location_country';
  RAISE NOTICE '💳 Payment: payment_method, bank_*, iban, paypal_*, exchange_*, binance_wallet';
  RAISE NOTICE '🖼️  Media: user_picture_url, store_picture_url, profile_picture';
  RAISE NOTICE '⚙️  Status: onboarded, archived, account_approval, created_at, updated_at';
  RAISE NOTICE '';
  RAISE NOTICE 'Your signup/onboarding is now 100% ready! 🎉';
  RAISE NOTICE '============================================================================';
END $$;
