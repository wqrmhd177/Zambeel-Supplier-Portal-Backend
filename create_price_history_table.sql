-- Create price_history table in Supabase
-- Run this SQL in your Supabase SQL editor

-- This table tracks all price changes for product variants
-- All operations are done directly from the frontend

CREATE TABLE IF NOT EXISTS price_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id BIGINT NOT NULL,
  variant_id BIGINT NOT NULL,
  previous_price DECIMAL(10, 2) NOT NULL,
  updated_price DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by_supplier_id TEXT,
  created_by_purchaser_id INTEGER
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_price_history_variant_id ON price_history(variant_id);
CREATE INDEX IF NOT EXISTS idx_price_history_product_id ON price_history(product_id);
CREATE INDEX IF NOT EXISTS idx_price_history_created_at ON price_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_price_history_created_by_supplier ON price_history(created_by_supplier_id);
CREATE INDEX IF NOT EXISTS idx_price_history_created_by_purchaser ON price_history(created_by_purchaser_id);

-- Add comments for documentation
COMMENT ON TABLE price_history IS 'Tracks all price changes for product variants (frontend-managed)';
COMMENT ON COLUMN price_history.id IS 'UUID primary key (auto-generated)';
COMMENT ON COLUMN price_history.product_id IS 'References products.product_id';
COMMENT ON COLUMN price_history.variant_id IS 'References products.variant_id';
COMMENT ON COLUMN price_history.previous_price IS 'The price before the change';
COMMENT ON COLUMN price_history.updated_price IS 'The new price after the change';
COMMENT ON COLUMN price_history.created_at IS 'When the price change occurred';
COMMENT ON COLUMN price_history.created_by_supplier_id IS 'Supplier ID (user_id) who made the change';
COMMENT ON COLUMN price_history.created_by_purchaser_id IS 'Purchaser ID if changed by purchaser';

-- Add constraint to ensure prices are positive
ALTER TABLE price_history 
ADD CONSTRAINT check_previous_price_positive 
CHECK (previous_price >= 0);

ALTER TABLE price_history 
ADD CONSTRAINT check_updated_price_positive 
CHECK (updated_price > 0);

-- Add constraint to ensure price actually changed
ALTER TABLE price_history 
ADD CONSTRAINT check_price_changed 
CHECK (previous_price != updated_price);

