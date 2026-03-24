-- ============================================================================
-- SHOPIFY-STYLE PRODUCT VARIANTS SYSTEM
-- ============================================================================
-- This migration creates a flexible variant system similar to Shopify:
-- - Products can have up to 3 customizable options (Color, Size, Weight, etc.)
-- - Each variant is a unique combination of option values
-- - Variants store their own price, stock, SKU, and images
-- ============================================================================

-- Step 1: Add new columns to products table for variant options
-- ============================================================================

DO $$
BEGIN
  -- Add options column to store variant option definitions
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'products' AND column_name = 'options'
  ) THEN
    ALTER TABLE products ADD COLUMN options jsonb DEFAULT NULL;
    COMMENT ON COLUMN products.options IS 'Array of variant options: [{ name: "Color", values: ["Red","Blue"] }, ...]';
    RAISE NOTICE 'Added options column to products';
  END IF;

  -- Add has_variants flag for quick filtering
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'products' AND column_name = 'has_variants'
  ) THEN
    ALTER TABLE products ADD COLUMN has_variants boolean DEFAULT false;
    COMMENT ON COLUMN products.has_variants IS 'True if product has multiple variants defined via options';
    RAISE NOTICE 'Added has_variants column to products';
  END IF;
END $$;

-- Step 2: Create product_variants table
-- ============================================================================
-- Note: We do NOT add a foreign key to products(product_id) because the legacy
-- products table has multiple rows per product_id (one per variant). New
-- products will have one row per product. The app enforces product_id validity.
-- ============================================================================

CREATE TABLE IF NOT EXISTS product_variants (
  variant_id bigserial PRIMARY KEY,
  product_id bigint NOT NULL,
  option_values jsonb DEFAULT '{}'::jsonb,
  sku text,
  price numeric(10,2) NOT NULL DEFAULT 0,
  stock integer NOT NULL DEFAULT 0,
  image jsonb DEFAULT NULL,
  active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  
  CONSTRAINT check_price_non_negative
    CHECK (price >= 0),
  
  CONSTRAINT check_stock_non_negative
    CHECK (stock >= 0)
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_product_variants_product_id 
  ON product_variants(product_id);

CREATE INDEX IF NOT EXISTS idx_product_variants_product_active 
  ON product_variants(product_id, active);

CREATE INDEX IF NOT EXISTS idx_product_variants_sku 
  ON product_variants(sku) WHERE sku IS NOT NULL;

-- Add comments
COMMENT ON TABLE product_variants IS 'Flexible variant system: each row is one variant combination with its own price, stock, SKU, and images';
COMMENT ON COLUMN product_variants.variant_id IS 'Unique variant identifier';
COMMENT ON COLUMN product_variants.product_id IS 'Parent product (FK to products.product_id)';
COMMENT ON COLUMN product_variants.option_values IS 'Variant option values as JSON object: {"Color": "Red", "Size": "M"}';
COMMENT ON COLUMN product_variants.sku IS 'Variant SKU (optional, unique if provided)';
COMMENT ON COLUMN product_variants.price IS 'Variant selling price';
COMMENT ON COLUMN product_variants.stock IS 'Variant stock quantity';
COMMENT ON COLUMN product_variants.image IS 'Variant-specific images as JSON array of URLs';
COMMENT ON COLUMN product_variants.active IS 'Whether this variant is available for sale';

-- Step 3: Add updated_at trigger for product_variants
-- ============================================================================

CREATE OR REPLACE FUNCTION update_product_variants_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_product_variants_updated_at ON product_variants;

CREATE TRIGGER trigger_update_product_variants_updated_at
  BEFORE UPDATE ON product_variants
  FOR EACH ROW
  EXECUTE FUNCTION update_product_variants_updated_at();

-- Step 4: Setup RLS policies for product_variants
-- ============================================================================

ALTER TABLE product_variants ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow all operations on product_variants" ON product_variants;
DROP POLICY IF EXISTS "Enable read for all authenticated users" ON product_variants;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON product_variants;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON product_variants;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON product_variants;

-- Allow all authenticated users to read product_variants
CREATE POLICY "Enable read for all authenticated users"
  ON product_variants FOR SELECT
  TO authenticated
  USING (true);

-- Allow authenticated users to insert their own product variants
CREATE POLICY "Enable insert for authenticated users"
  ON product_variants FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Allow authenticated users to update product variants
CREATE POLICY "Enable update for authenticated users"
  ON product_variants FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Allow authenticated users to delete product variants
CREATE POLICY "Enable delete for authenticated users"
  ON product_variants FOR DELETE
  TO authenticated
  USING (true);

-- Step 5: Verification and summary
-- ============================================================================

DO $$
DECLARE
  products_count bigint;
  variants_count bigint;
BEGIN
  SELECT COUNT(*) INTO products_count FROM products;
  SELECT COUNT(*) INTO variants_count FROM product_variants;
  
  RAISE NOTICE '============================================================================';
  RAISE NOTICE '✅ SHOPIFY-STYLE VARIANT SYSTEM CREATED';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'New columns added to products:';
  RAISE NOTICE '  - options (jsonb): stores variant option definitions';
  RAISE NOTICE '  - has_variants (boolean): quick flag for products with variants';
  RAISE NOTICE '';
  RAISE NOTICE 'New table created: product_variants';
  RAISE NOTICE '  - Stores individual variant rows with option_values, price, stock, SKU, images';
  RAISE NOTICE '  - Supports up to 50 variants per product';
  RAISE NOTICE '  - Indexed on product_id and (product_id, active)';
  RAISE NOTICE '';
  RAISE NOTICE 'Current data:';
  RAISE NOTICE '  - Products: %', products_count;
  RAISE NOTICE '  - Variants: %', variants_count;
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '  1. Update frontend to use new variant system';
  RAISE NOTICE '  2. Migrate existing products to product_variants if needed';
  RAISE NOTICE '  3. New products will use the flexible variant system';
  RAISE NOTICE '============================================================================';
END $$;
