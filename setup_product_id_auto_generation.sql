-- ============================================================================
-- AUTO-GENERATE product_id AND variant_id FOR PRODUCTS TABLE
-- ============================================================================
-- This creates sequences and triggers to automatically generate IDs
-- ============================================================================

-- Create sequences for product_id and variant_id
CREATE SEQUENCE IF NOT EXISTS products_product_id_seq START WITH 1;
CREATE SEQUENCE IF NOT EXISTS products_variant_id_seq START WITH 1;

-- Make product_id and variant_id columns use sequences as default
ALTER TABLE products 
ALTER COLUMN product_id SET DEFAULT nextval('products_product_id_seq');

ALTER TABLE products 
ALTER COLUMN variant_id SET DEFAULT nextval('products_variant_id_seq');

-- Make the columns nullable temporarily (in case some already exist without values)
ALTER TABLE products 
ALTER COLUMN product_id DROP NOT NULL;

ALTER TABLE products 
ALTER COLUMN variant_id DROP NOT NULL;

-- Update existing NULL values with sequence values
UPDATE products 
SET product_id = nextval('products_product_id_seq') 
WHERE product_id IS NULL;

UPDATE products 
SET variant_id = nextval('products_variant_id_seq') 
WHERE variant_id IS NULL;

-- Make them NOT NULL again
ALTER TABLE products 
ALTER COLUMN product_id SET NOT NULL;

ALTER TABLE products 
ALTER COLUMN variant_id SET NOT NULL;

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE '✅ PRODUCT ID AUTO-GENERATION CONFIGURED!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'product_id and variant_id will now auto-generate starting from 1, 2, 3...';
  RAISE NOTICE '';
  RAISE NOTICE 'How it works:';
  RAISE NOTICE '  - If you do not provide product_id, it auto-generates';
  RAISE NOTICE '  - If you do not provide variant_id, it auto-generates';
  RAISE NOTICE '  - You can still manually set these values if needed';
  RAISE NOTICE '';
  RAISE NOTICE 'Product creation should now work! 🎉';
  RAISE NOTICE '============================================================================';
END $$;
