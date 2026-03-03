-- Migration: Rename created_by_user_id to created_by_supplier_id
-- Run this SQL in your Supabase SQL editor if you already created the price_history table

-- Rename the column
ALTER TABLE price_history 
RENAME COLUMN created_by_user_id TO created_by_supplier_id;

-- Drop old index
DROP INDEX IF EXISTS idx_price_history_created_by_user;

-- Create new index with correct name
CREATE INDEX IF NOT EXISTS idx_price_history_created_by_supplier ON price_history(created_by_supplier_id);

-- Update comment
COMMENT ON COLUMN price_history.created_by_supplier_id IS 'Supplier ID (user_id) who made the change';

-- Verify the change
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'price_history' 
  AND column_name = 'created_by_supplier_id';

