-- ============================================================================
-- SETUP RLS POLICIES FOR PRODUCTS TABLE
-- ============================================================================
-- This creates permissive RLS policies to allow product operations
-- ============================================================================

-- Enable RLS on products table
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow all operations on products" ON products;
DROP POLICY IF EXISTS "Enable all access for products" ON products;

-- Create a single permissive policy that allows all operations
CREATE POLICY "Enable all access for products"
ON products
FOR ALL
TO public
USING (true)
WITH CHECK (true);

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE '✅ PRODUCTS RLS POLICY CONFIGURED!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'All operations (SELECT, INSERT, UPDATE, DELETE) are now allowed on products.';
  RAISE NOTICE 'This is appropriate for custom authentication systems.';
  RAISE NOTICE '';
  RAISE NOTICE 'Product creation should now work! 🎉';
  RAISE NOTICE '============================================================================';
END $$;
