-- ============================================================================
-- FIX: Allow "pending" status so Add New Product works (drops check_status_valid)
-- ============================================================================
-- Run this once in Supabase → SQL Editor. Then try adding a product again.
-- ============================================================================

-- Remove the constraint that only allows active/inactive
ALTER TABLE products DROP CONSTRAINT IF EXISTS check_status_valid;
ALTER TABLE products DROP CONSTRAINT IF EXISTS products_status_check;
ALTER TABLE products DROP CONSTRAINT IF EXISTS products_status_fkey;

-- Allow: pending, active, inactive, rejected
ALTER TABLE products
  ADD CONSTRAINT products_status_check
  CHECK (status IN ('pending', 'active', 'inactive', 'rejected'));

-- Default for new rows
ALTER TABLE products ALTER COLUMN status SET DEFAULT 'pending';

-- Fix any NULL status
UPDATE products SET status = 'pending' WHERE status IS NULL;
