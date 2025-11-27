-- Create orders table in Supabase
-- Run this SQL in your Supabase SQL editor

CREATE TABLE IF NOT EXISTS orders (
  id BIGSERIAL PRIMARY KEY,
  order_id BIGINT NOT NULL,
  vendor_id TEXT,
  order_date TIMESTAMPTZ,
  phone TEXT,
  country TEXT,
  title TEXT,
  sku TEXT NOT NULL,
  total_payable DECIMAL(10, 2),
  status TEXT,
  UNIQUE(order_id, sku)
);

-- Note: Composite unique constraint on (order_id, sku) for upsert operations

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_orders_order_id ON orders(order_id);
CREATE INDEX IF NOT EXISTS idx_orders_vendor_id ON orders(vendor_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON orders(order_date);
CREATE INDEX IF NOT EXISTS idx_orders_sku ON orders(sku);


-- Add comments for documentation
COMMENT ON TABLE orders IS 'Orders data synced from Metabase';
COMMENT ON COLUMN orders.order_id IS 'Unique order ID from Metabase';
COMMENT ON COLUMN orders.vendor_id IS 'Vendor/supplier ID';
COMMENT ON COLUMN orders.sku IS 'Product SKU (company_sku from products table)';

