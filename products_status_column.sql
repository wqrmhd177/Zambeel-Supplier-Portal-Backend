-- ============================================================================
-- PRODUCTS STATUS COLUMN: pending, active, rejected (and inactive for backwards compat)
-- ============================================================================
-- Run this in Supabase SQL Editor to:
-- 1. Allow status values: pending, active, inactive, rejected
-- 2. Set default to 'pending' for new products
-- 3. Ensure existing rows have a valid status
-- ============================================================================

-- Ensure status column exists and is text (if your column is different type, adjust)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'products' AND column_name = 'status'
  ) THEN
    ALTER TABLE products ADD COLUMN status text DEFAULT 'pending';
    RAISE NOTICE 'Added status column with default pending';
  END IF;
END $$;

-- Drop any existing check constraint on status (names may vary)
ALTER TABLE products DROP CONSTRAINT IF EXISTS products_status_check;
ALTER TABLE products DROP CONSTRAINT IF EXISTS products_status_fkey;
ALTER TABLE products DROP CONSTRAINT IF EXISTS check_status_valid;

-- Allow only these values: pending (new), active (approved), inactive/rejected (rejected)
ALTER TABLE products
  ADD CONSTRAINT products_status_check
  CHECK (status IN ('pending', 'active', 'inactive', 'rejected'));

-- Set default so every new product gets 'pending' when status is not provided
ALTER TABLE products ALTER COLUMN status SET DEFAULT 'pending';

-- Backfill: rows with NULL status -> pending
UPDATE products SET status = 'pending' WHERE status IS NULL;

-- Optional: move existing "active" products that have no SKU into New Products (so agent can process them)
-- Uncomment to run once if you have such rows:
-- UPDATE products p SET status = 'pending'
-- WHERE p.status = 'active'
--   AND (p.company_sku IS NULL OR trim(p.company_sku) = '');

-- Optional: treat old 'inactive' as rejected (no data change needed; UI shows both as Rejected)
-- To normalize to only 'rejected' instead of 'inactive', uncomment next line:
-- UPDATE products SET status = 'rejected' WHERE status = 'inactive';

COMMENT ON COLUMN products.status IS 'Product listing status: pending (new, in New Products), active (approved, SKU assigned), inactive/rejected (in Rejected Products)';

-- Verify
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE '✅ PRODUCTS STATUS COLUMN UPDATED';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'Allowed values: pending, active, inactive, rejected';
  RAISE NOTICE 'Default for new rows: pending';
  RAISE NOTICE 'New products will appear in Listings > New Products until agent assigns SKU and approves.';
  RAISE NOTICE '============================================================================';
END $$;
