-- ============================================================================
-- MIGRATE LEGACY PRODUCTS TO NEW VARIANT SYSTEM
-- ============================================================================
-- This script migrates existing products from the legacy model (multiple rows
-- per product in the products table) to the new variant system (one row in
-- products, multiple rows in product_variants).
--
-- IMPORTANT: Run this AFTER the create_product_variants_table.sql migration
-- and AFTER verifying the new system works with new products.
--
-- This is a LATER task - only run when ready to fully migrate.
-- ============================================================================

-- Step 1: Identify products that need migration
-- ============================================================================
-- Products with variant_id in the products table are legacy products

DO $$
DECLARE
  legacy_count bigint;
  product_count bigint;
BEGIN
  -- Count legacy variant rows (products table rows with variant_id)
  SELECT COUNT(*) INTO legacy_count
  FROM products
  WHERE variant_id IS NOT NULL;
  
  -- Count distinct products
  SELECT COUNT(DISTINCT product_id) INTO product_count
  FROM products
  WHERE variant_id IS NOT NULL;
  
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'LEGACY PRODUCTS MIGRATION ANALYSIS';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'Legacy variant rows in products table: %', legacy_count;
  RAISE NOTICE 'Distinct products to migrate: %', product_count;
  RAISE NOTICE '============================================================================';
END $$;

-- Step 2: Migrate legacy products to product_variants
-- ============================================================================
-- For each product with variant_id, create corresponding product_variants rows

INSERT INTO product_variants (
  product_id,
  option_values,
  sku,
  price,
  stock,
  image,
  active,
  created_at,
  updated_at
)
SELECT
  p.product_id,
  -- Build option_values from legacy size/color fields
  jsonb_build_object(
    'Color', COALESCE(p.color, ''),
    'Size', COALESCE(
      CASE 
        WHEN p.size_category IS NOT NULL AND p.size IS NOT NULL 
        THEN p.size || ' ' || p.size_category
        WHEN p.size IS NOT NULL 
        THEN p.size
        ELSE ''
      END,
      ''
    )
  ) - '' AS option_values, -- Remove empty string keys
  NULL AS sku, -- Legacy products don't have variant-level SKU
  COALESCE(p.variant_selling_price, 0) AS price,
  COALESCE(p.variant_stock, 0) AS stock,
  p.image AS image,
  true AS active, -- All legacy variants are active
  p.created_at,
  p.updated_at
FROM products p
WHERE p.variant_id IS NOT NULL
  AND NOT EXISTS (
    -- Don't migrate if already migrated
    SELECT 1 FROM product_variants pv
    WHERE pv.product_id = p.product_id
  );

-- Step 3: Update products table to set has_variants flag
-- ============================================================================
-- For migrated products, set has_variants = true if they have multiple variants

UPDATE products p
SET has_variants = (
  SELECT COUNT(*) > 1
  FROM product_variants pv
  WHERE pv.product_id = p.product_id
)
WHERE EXISTS (
  SELECT 1 FROM product_variants pv
  WHERE pv.product_id = p.product_id
);

-- Step 4: Verification
-- ============================================================================

DO $$
DECLARE
  migrated_products bigint;
  migrated_variants bigint;
BEGIN
  SELECT COUNT(DISTINCT product_id) INTO migrated_products
  FROM product_variants;
  
  SELECT COUNT(*) INTO migrated_variants
  FROM product_variants;
  
  RAISE NOTICE '============================================================================';
  RAISE NOTICE '✅ MIGRATION COMPLETE';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'Products migrated: %', migrated_products;
  RAISE NOTICE 'Total variants in product_variants: %', migrated_variants;
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '  1. Verify products display correctly in the UI';
  RAISE NOTICE '  2. Test editing and updating products';
  RAISE NOTICE '  3. Once verified, you can optionally drop legacy columns:';
  RAISE NOTICE '     - variant_id, size, size_category, color';
  RAISE NOTICE '     - variant_selling_price, variant_stock';
  RAISE NOTICE '============================================================================';
END $$;

-- ============================================================================
-- OPTIONAL: Drop legacy columns (ONLY after verifying migration success)
-- ============================================================================
-- Uncomment these lines ONLY after thoroughly testing the new system:

-- ALTER TABLE products DROP COLUMN IF EXISTS variant_id;
-- ALTER TABLE products DROP COLUMN IF EXISTS size;
-- ALTER TABLE products DROP COLUMN IF EXISTS size_category;
-- ALTER TABLE products DROP COLUMN IF EXISTS color;
-- ALTER TABLE products DROP COLUMN IF EXISTS variant_selling_price;
-- ALTER TABLE products DROP COLUMN IF EXISTS variant_stock;

-- RAISE NOTICE 'Legacy variant columns dropped from products table';
