-- ============================================================================
-- ADD MISSING COLUMNS TO PRODUCTS TABLE
-- ============================================================================
-- This adds all missing columns that the product form uses
-- ============================================================================

-- Add missing columns to products table
ALTER TABLE products 
ADD COLUMN IF NOT EXISTS brand_name TEXT,
ADD COLUMN IF NOT EXISTS material TEXT,
ADD COLUMN IF NOT EXISTS package_includes JSONB,
ADD COLUMN IF NOT EXISTS size_category TEXT;

-- Add comments
COMMENT ON COLUMN products.brand_name IS 'Product brand name';
COMMENT ON COLUMN products.material IS 'Product material composition';
COMMENT ON COLUMN products.package_includes IS 'Array of items included in package';
COMMENT ON COLUMN products.size_category IS 'Size category (e.g., Small, Medium, Large, XL)';

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_products_brand_name ON products(brand_name);
CREATE INDEX IF NOT EXISTS idx_products_material ON products(material);

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE '✅ PRODUCT COLUMNS ADDED SUCCESSFULLY!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'Added columns:';
  RAISE NOTICE '  - brand_name (Product brand)';
  RAISE NOTICE '  - material (Product material)';
  RAISE NOTICE '  - package_includes (Package contents as JSON array)';
  RAISE NOTICE '  - size_category (Size category)';
  RAISE NOTICE '';
  RAISE NOTICE 'Product creation should now work! 🎉';
  RAISE NOTICE '============================================================================';
END $$;
