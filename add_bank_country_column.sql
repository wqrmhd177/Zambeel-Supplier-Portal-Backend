-- Migration: Add bank_country column to users table
-- This allows suppliers to specify which country their bank account is in,
-- separate from their living country

-- Add bank_country column
ALTER TABLE users ADD COLUMN IF NOT EXISTS bank_country TEXT;

-- Add comment for documentation
COMMENT ON COLUMN users.bank_country IS 'Country where the supplier bank account is located';

-- Query example:
-- SELECT id, country as living_country, bank_country, bank_name, iban FROM users WHERE bank_country IS NOT NULL;
