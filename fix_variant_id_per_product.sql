-- ============================================================================
-- FIX VARIANT ID TO RESTART FOR EACH PRODUCT
-- ============================================================================
-- This changes variant_id to be unique per product, not globally unique
-- ============================================================================

-- Step 1: Drop the global unique constraint on variant_id
ALTER TABLE products DROP CONSTRAINT IF EXISTS products_variant_id_key;

-- Step 2: Add composite unique constraint (product_id + variant_id together must be unique)
ALTER TABLE products DROP CONSTRAINT IF EXISTS products_product_variant_unique;
ALTER TABLE products 
ADD CONSTRAINT products_product_variant_unique UNIQUE (product_id, variant_id);

-- Step 3: Remove the default on variant_id (we'll set it in frontend)
ALTER TABLE products 
ALTER COLUMN variant_id DROP DEFAULT;

-- Step 4: Make variant_id nullable temporarily
ALTER TABLE products 
ALTER COLUMN variant_id DROP NOT NULL;

-- Step 5: Drop the variant_id sequence (not needed anymore)
DROP SEQUENCE IF EXISTS products_variant_id_seq;

-- Step 6: Update existing products to have proper variant_ids (1, 2, 3 per product)
DO $$
DECLARE
  prod_id BIGINT;
  row_num INT;
BEGIN
  FOR prod_id IN (SELECT DISTINCT product_id FROM products WHERE product_id IS NOT NULL ORDER BY product_id)
  LOOP
    row_num := 0;
    UPDATE products 
    SET variant_id = (
      SELECT ROW_NUMBER() OVER (ORDER BY id)
      FROM products p2 
      WHERE p2.product_id = products.product_id AND p2.id = products.id
    )
    WHERE product_id = prod_id;
  END LOOP;
END $$;

-- Step 7: Make variant_id NOT NULL again
ALTER TABLE products 
ALTER COLUMN variant_id SET NOT NULL;

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE '✅ VARIANT ID FIXED - NOW UNIQUE PER PRODUCT!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'Changes made:';
  RAISE NOTICE '  - product_id: Auto-increments globally (1, 2, 3, 4...)';
  RAISE NOTICE '  - variant_id: Restarts from 1 for EACH product';
  RAISE NOTICE '';
  RAISE NOTICE 'Example:';
  RAISE NOTICE '  Product 1: variant_id 1, 2, 3';
  RAISE NOTICE '  Product 2: variant_id 1, 2, 3';
  RAISE NOTICE '  Product 3: variant_id 1, 2, 3';
  RAISE NOTICE '';
  RAISE NOTICE 'Note: Frontend must assign variant_id as 1, 2, 3 for each product';
  RAISE NOTICE '============================================================================';
END $$;
