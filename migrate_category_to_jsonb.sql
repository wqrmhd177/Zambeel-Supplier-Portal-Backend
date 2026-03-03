-- Migration: Convert category column from TEXT to JSONB
-- This allows efficient querying and analytics for categories
-- No backfill needed - no users onboarded yet

-- Step 1: Drop existing column if it exists
ALTER TABLE users DROP COLUMN IF EXISTS category;

-- Step 2: Add category as JSONB
ALTER TABLE users ADD COLUMN category JSONB;

-- Step 3: Add GIN index for efficient querying
CREATE INDEX idx_users_category ON users USING gin(category);

-- Query examples after migration:
-- - Find suppliers in Electronics: WHERE category @> '["Electronics"]'
-- - Find suppliers in multiple categories: WHERE category ?| array['Electronics', 'Mobile Phones & Accessories']
-- - Count suppliers per category: SELECT jsonb_array_elements_text(category), COUNT(*) FROM users GROUP BY 1
