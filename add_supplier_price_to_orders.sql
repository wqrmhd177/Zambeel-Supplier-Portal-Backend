-- Add supplier_selling_price column to orders table
-- Run this SQL in your Supabase SQL editor

-- Add the column to store historical supplier selling price
ALTER TABLE orders 
ADD COLUMN IF NOT EXISTS supplier_selling_price DECIMAL(10, 2);

-- Add index for faster queries and filtering
CREATE INDEX IF NOT EXISTS idx_orders_supplier_price 
ON orders(supplier_selling_price);

-- Add comment for documentation
COMMENT ON COLUMN orders.supplier_selling_price 
IS 'Supplier selling price at the time of order (historical price from price_history table, populated by backend sync script)';

-- Verify the column was added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'orders' AND column_name = 'supplier_selling_price';

