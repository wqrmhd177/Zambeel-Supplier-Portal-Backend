-- Add country column to users table
ALTER TABLE users
ADD COLUMN IF NOT EXISTS country TEXT;

-- Optional: Add comment for documentation
COMMENT ON COLUMN users.country IS 'Country of operation: Pakistan, United Arab Emirates, or Saudia Arabia';

