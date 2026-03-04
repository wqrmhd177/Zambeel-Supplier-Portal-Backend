-- ============================================================================
-- VERIFY AND FIX PRODUCT_ID AUTO-GENERATION
-- ============================================================================
-- This ensures product_id auto-generates correctly
-- ============================================================================

-- First, verify the sequence exists and is owned by the column
DO $$
BEGIN
    -- Create sequence if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM pg_sequences WHERE schemaname = 'public' AND sequencename = 'products_product_id_seq') THEN
        CREATE SEQUENCE products_product_id_seq START WITH 1;
        RAISE NOTICE 'Created products_product_id_seq sequence';
    ELSE
        RAISE NOTICE 'Sequence products_product_id_seq already exists';
    END IF;
END $$;

-- Set the sequence as owned by the product_id column
ALTER SEQUENCE products_product_id_seq OWNED BY products.product_id;

-- Set the default value for product_id to use the sequence
ALTER TABLE products 
ALTER COLUMN product_id SET DEFAULT nextval('products_product_id_seq');

-- Make product_id nullable temporarily to fix existing data
ALTER TABLE products 
ALTER COLUMN product_id DROP NOT NULL;

-- Update any NULL product_id values
UPDATE products 
SET product_id = nextval('products_product_id_seq') 
WHERE product_id IS NULL;

-- Make product_id required again
ALTER TABLE products 
ALTER COLUMN product_id SET NOT NULL;

-- Show current sequence value
SELECT 'Current sequence value: ' || currval('products_product_id_seq') AS info;

-- Test the default (this will show the next value that will be used)
SELECT 'Next product_id will be: ' || nextval('products_product_id_seq') AS next_value;

-- Reset to previous value (since we just tested)
SELECT setval('products_product_id_seq', currval('products_product_id_seq') - 1);

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE '✅ PRODUCT_ID AUTO-GENERATION VERIFIED AND FIXED!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'The sequence is now properly configured.';
  RAISE NOTICE 'When inserting products WITHOUT product_id, it will auto-generate.';
  RAISE NOTICE '============================================================================';
END $$;
