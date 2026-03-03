-- Add composite index for efficient historical price lookups
-- Run this SQL in your Supabase SQL editor

-- This index optimizes queries that look up historical prices by:
-- 1. variant_id (exact match)
-- 2. status (filter for 'approved' only)
-- 3. created_at (order by DESC to get most recent)
CREATE INDEX IF NOT EXISTS idx_price_history_variant_status_date 
ON price_history(variant_id, status, created_at DESC);

-- Add comment for documentation
COMMENT ON INDEX idx_price_history_variant_status_date 
IS 'Optimizes historical price lookups by variant_id, status, and date. Used by backend sync script to find the most recent approved price before order date.';

-- Verify the index was created
SELECT 
    indexname, 
    indexdef 
FROM pg_indexes 
WHERE tablename = 'price_history' 
AND indexname = 'idx_price_history_variant_status_date';

