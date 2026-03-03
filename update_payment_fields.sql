-- Migration: Update payment method fields in users table
-- This adds new fields for PayPal account name and Crypto payment details
-- Also removes the old binance_wallet field

-- Add PayPal account name field
ALTER TABLE users ADD COLUMN IF NOT EXISTS paypal_account_name TEXT;

-- Add Crypto payment fields
ALTER TABLE users ADD COLUMN IF NOT EXISTS exchange_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS exchange_account_name TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS exchange_id TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS exchange_country TEXT;

-- Keep binance_wallet column (add if it doesn't exist)
ALTER TABLE users ADD COLUMN IF NOT EXISTS binance_wallet TEXT;

-- Add comments for documentation
COMMENT ON COLUMN users.paypal_account_name IS 'Name registered on PayPal account';
COMMENT ON COLUMN users.exchange_name IS 'Name of crypto exchange (e.g., Binance, Coinbase)';
COMMENT ON COLUMN users.exchange_account_name IS 'Registered name on the exchange';
COMMENT ON COLUMN users.exchange_id IS 'Exchange user ID or wallet address';
COMMENT ON COLUMN users.exchange_country IS 'Country where exchange account is registered';
COMMENT ON COLUMN users.binance_wallet IS 'Crypto wallet address for receiving payments';

-- Query examples:
-- Find suppliers using PayPal: SELECT * FROM users WHERE payment_method = 'Paypal';
-- Find suppliers using Crypto: SELECT * FROM users WHERE payment_method = 'Crypto Payments';
-- Get all exchange details: SELECT id, full_name, exchange_name, exchange_id, exchange_country FROM users WHERE exchange_name IS NOT NULL;
