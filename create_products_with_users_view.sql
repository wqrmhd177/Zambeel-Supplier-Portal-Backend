-- ============================================================================
-- CREATE VIEW: PRODUCTS WITH USER INFORMATION
-- ============================================================================
-- This creates a view to easily see which user owns which product
-- ============================================================================

-- Create view that joins products with users
CREATE OR REPLACE VIEW products_with_users AS
SELECT 
  p.id,
  p.product_id,
  p.variant_id,
  p.product_title,
  p.brand_name,
  p.fk_owned_by AS user_id,
  u.full_name AS owner_name,
  u.owner_name AS store_owner,
  u.shop_name_on_zambeel AS shop_name,
  u.email AS owner_email,
  u.role AS user_role,
  u.country AS owner_country,
  p.size,
  p.size_category,
  p.color,
  p.variant_selling_price,
  p.variant_stock,
  p.company_sku,
  p.status,
  p.image,
  p.created_at,
  p.updated_at
FROM products p
LEFT JOIN users u ON p.fk_owned_by = u.user_id
ORDER BY p.created_at DESC;

-- Add comment
COMMENT ON VIEW products_with_users IS 'Products table joined with user information for easy viewing';

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE '✅ PRODUCTS_WITH_USERS VIEW CREATED!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'You can now query: SELECT * FROM products_with_users';
  RAISE NOTICE '';
  RAISE NOTICE 'This view shows:';
  RAISE NOTICE '  - Product information';
  RAISE NOTICE '  - Owner user_id, name, email, role';
  RAISE NOTICE '  - Shop name and country';
  RAISE NOTICE '';
  RAISE NOTICE 'Use this in Table Editor or SQL queries to see which user owns which product!';
  RAISE NOTICE '============================================================================';
END $$;
