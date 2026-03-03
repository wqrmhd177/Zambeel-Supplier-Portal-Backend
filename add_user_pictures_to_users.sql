-- Add user and store picture URLs to users table
ALTER TABLE users
ADD COLUMN IF NOT EXISTS user_picture_url TEXT,
ADD COLUMN IF NOT EXISTS store_picture_url TEXT;

-- Optional: ensure updated_at tracked
-- Applications should set updated_at on updates; no trigger added here.

