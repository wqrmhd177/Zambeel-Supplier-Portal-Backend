-- ============================================================================
-- SUPPLIER PORTAL - COMPLETE DATABASE SETUP SCRIPT
-- ============================================================================
-- This script creates all essential tables, indexes, constraints, and comments
-- for the Zambeel Supplier Portal project
-- 
-- IMPORTANT: This matches your existing 4-table structure
-- ============================================================================

-- ============================================================================
-- 1. USERS TABLE
-- ============================================================================
-- Stores all user accounts (suppliers, purchasers, agents, admins)
-- 
-- IMPORTANT FIELDS:
-- - id (SERIAL): Auto-increment ID, used in price_history.created_by_purchaser_id
-- - user_id (TEXT): Friendly ID (SUP001, PUR001), used throughout the app
-- - purchaser_id (INTEGER): For suppliers only - references the purchaser managing them
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  user_id TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password TEXT,
  role TEXT NOT NULL DEFAULT 'supplier',
  owner_name TEXT,
  store_name TEXT,
  phone_number TEXT,
  city TEXT,
  country TEXT,
  currency TEXT DEFAULT 'USD',
  bank_name TEXT,
  bank_account_number TEXT,
  bank_account_title TEXT,
  bank_country TEXT,
  profile_picture TEXT,
  purchaser_id INTEGER,
  onboarded BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT check_role_valid CHECK (role IN ('supplier', 'purchaser', 'agent', 'admin')),
  CONSTRAINT check_currency_valid CHECK (currency IN ('USD', 'PKR', 'AED', 'EUR', 'GBP', 'SAR', 'OMR', 'BHD', 'KWD', 'QAR'))
);

-- Indexes for users table
CREATE INDEX IF NOT EXISTS idx_users_user_id ON users(user_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_purchaser_id ON users(purchaser_id);
CREATE INDEX IF NOT EXISTS idx_users_onboarded ON users(onboarded);

-- Comments for users table
COMMENT ON TABLE users IS 'Stores all user accounts for suppliers, purchasers, agents, and admins';
COMMENT ON COLUMN users.id IS 'Serial ID (auto-increment), used as purchaser_id in price_history table';
COMMENT ON COLUMN users.user_id IS 'Friendly user identifier (e.g., SUP001, PUR001)';
COMMENT ON COLUMN users.role IS 'User role: supplier, purchaser, agent, or admin';
COMMENT ON COLUMN users.purchaser_id IS 'For suppliers only: references users.id of the purchaser managing this supplier';
COMMENT ON COLUMN users.currency IS 'Default currency for the user (USD, PKR, AED, etc.)';
COMMENT ON COLUMN users.onboarded IS 'Whether the user has completed onboarding';


-- ============================================================================
-- 2. PRODUCTS TABLE
-- ============================================================================
-- Stores product information with variants
-- Each row represents a product variant
-- ============================================================================

CREATE TABLE IF NOT EXISTS products (
  id BIGSERIAL PRIMARY KEY,
  product_id BIGINT NOT NULL,
  variant_id BIGINT UNIQUE NOT NULL,
  product_title TEXT NOT NULL,
  fk_owned_by TEXT NOT NULL,
  image JSONB,
  size TEXT,
  color TEXT,
  company_sku TEXT,
  variant_selling_price DECIMAL(10, 2) NOT NULL DEFAULT 0,
  variant_stock INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'active',
  category JSONB,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT check_status_valid CHECK (status IN ('active', 'inactive')),
  CONSTRAINT check_price_positive CHECK (variant_selling_price >= 0),
  CONSTRAINT check_stock_positive CHECK (variant_stock >= 0)
);

-- Indexes for products table
CREATE INDEX IF NOT EXISTS idx_products_product_id ON products(product_id);
CREATE INDEX IF NOT EXISTS idx_products_variant_id ON products(variant_id);
CREATE INDEX IF NOT EXISTS idx_products_owned_by ON products(fk_owned_by);
CREATE INDEX IF NOT EXISTS idx_products_company_sku ON products(company_sku);
CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products(created_at DESC);

-- Comments for products table
COMMENT ON TABLE products IS 'Stores product information with variants (one row per variant)';
COMMENT ON COLUMN products.product_id IS 'Groups variants of the same product together';
COMMENT ON COLUMN products.variant_id IS 'Unique identifier for each variant';
COMMENT ON COLUMN products.fk_owned_by IS 'References users.user_id (supplier who owns this product)';
COMMENT ON COLUMN products.image IS 'Array of image URLs stored as JSONB';
COMMENT ON COLUMN products.company_sku IS 'SKU assigned by Zambeel (required for product to be active)';
COMMENT ON COLUMN products.variant_selling_price IS 'Selling price for this variant';
COMMENT ON COLUMN products.variant_stock IS 'Available stock for this variant';
COMMENT ON COLUMN products.status IS 'Product status: active or inactive';


-- ============================================================================
-- 3. ORDERS TABLE
-- ============================================================================
-- Stores orders synced from Metabase
-- Composite unique key on (order_id, sku)
-- ============================================================================

CREATE TABLE IF NOT EXISTS orders (
  id BIGSERIAL PRIMARY KEY,
  order_id BIGINT NOT NULL,
  vendor_id TEXT,
  order_date TIMESTAMPTZ,
  phone TEXT,
  country TEXT,
  title TEXT,
  sku TEXT NOT NULL,
  quantity INTEGER DEFAULT 1,
  supplier_selling_price DECIMAL(10, 2),
  total_payable DECIMAL(10, 2),
  status TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_order_sku UNIQUE(order_id, sku)
);

-- Indexes for orders table
CREATE INDEX IF NOT EXISTS idx_orders_order_id ON orders(order_id);
CREATE INDEX IF NOT EXISTS idx_orders_vendor_id ON orders(vendor_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON orders(order_date DESC);
CREATE INDEX IF NOT EXISTS idx_orders_sku ON orders(sku);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- Comments for orders table
COMMENT ON TABLE orders IS 'Orders data synced from Metabase';
COMMENT ON COLUMN orders.order_id IS 'Order ID from Metabase';
COMMENT ON COLUMN orders.vendor_id IS 'References users.user_id (supplier)';
COMMENT ON COLUMN orders.sku IS 'Product SKU (company_sku from products table)';
COMMENT ON COLUMN orders.supplier_selling_price IS 'Historical supplier price at time of order';
COMMENT ON COLUMN orders.total_payable IS 'Total amount payable for the order';
COMMENT ON COLUMN orders.quantity IS 'Quantity ordered';


-- ============================================================================
-- 4. PRICE_HISTORY TABLE
-- ============================================================================
-- Tracks all price changes and approval workflow
-- Used for historical pricing and price change approvals
-- Note: created_by_purchaser_id references users.id (not user_id)
-- ============================================================================

CREATE TABLE IF NOT EXISTS price_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id BIGINT NOT NULL,
  variant_id BIGINT NOT NULL,
  previous_price DECIMAL(10, 2) NOT NULL,
  updated_price DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by_supplier_id TEXT,
  created_by_purchaser_id INTEGER,
  status TEXT NOT NULL DEFAULT 'pending',
  reviewed_at TIMESTAMPTZ,
  reviewed_by TEXT,
  notes TEXT,
  CONSTRAINT check_previous_price_positive CHECK (previous_price >= 0),
  CONSTRAINT check_updated_price_positive CHECK (updated_price > 0),
  CONSTRAINT check_price_changed CHECK (previous_price != updated_price),
  CONSTRAINT check_status_valid CHECK (status IN ('pending', 'approved', 'rejected'))
);

-- Indexes for price_history table
CREATE INDEX IF NOT EXISTS idx_price_history_variant_id ON price_history(variant_id);
CREATE INDEX IF NOT EXISTS idx_price_history_product_id ON price_history(product_id);
CREATE INDEX IF NOT EXISTS idx_price_history_created_at ON price_history(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_price_history_created_by_supplier ON price_history(created_by_supplier_id);
CREATE INDEX IF NOT EXISTS idx_price_history_created_by_purchaser ON price_history(created_by_purchaser_id);
CREATE INDEX IF NOT EXISTS idx_price_history_status ON price_history(status);
CREATE INDEX IF NOT EXISTS idx_price_history_composite ON price_history(variant_id, created_at DESC, status);

-- Comments for price_history table
COMMENT ON TABLE price_history IS 'Tracks all price changes for product variants with approval workflow';
COMMENT ON COLUMN price_history.id IS 'UUID primary key (auto-generated)';
COMMENT ON COLUMN price_history.product_id IS 'References products.product_id';
COMMENT ON COLUMN price_history.variant_id IS 'References products.variant_id';
COMMENT ON COLUMN price_history.previous_price IS 'The price before the change';
COMMENT ON COLUMN price_history.updated_price IS 'The new price after the change';
COMMENT ON COLUMN price_history.created_by_supplier_id IS 'Supplier user_id (TEXT) who requested the change';
COMMENT ON COLUMN price_history.created_by_purchaser_id IS 'Purchaser ID (INTEGER - references users.id) if changed by purchaser';
COMMENT ON COLUMN price_history.status IS 'Approval status: pending, approved, or rejected';
COMMENT ON COLUMN price_history.reviewed_at IS 'When the request was reviewed by an agent';
COMMENT ON COLUMN price_history.reviewed_by IS 'Agent user_id who reviewed the request';
COMMENT ON COLUMN price_history.notes IS 'Optional notes from reviewer (e.g., rejection reason)';




-- ============================================================================
-- 5. FOREIGN KEY CONSTRAINTS (Optional)
-- ============================================================================
-- Add foreign key relationships between tables
-- Uncomment if you want to enforce referential integrity
-- ============================================================================

-- Products table foreign keys
-- ALTER TABLE products ADD CONSTRAINT fk_products_owner 
--   FOREIGN KEY (fk_owned_by) REFERENCES users(user_id) ON DELETE CASCADE;

-- Orders table foreign keys
-- ALTER TABLE orders ADD CONSTRAINT fk_orders_vendor 
--   FOREIGN KEY (vendor_id) REFERENCES users(user_id) ON DELETE SET NULL;

-- Price history foreign keys
-- ALTER TABLE price_history ADD CONSTRAINT fk_price_history_supplier 
--   FOREIGN KEY (created_by_supplier_id) REFERENCES users(user_id) ON DELETE SET NULL;
-- ALTER TABLE price_history ADD CONSTRAINT fk_price_history_purchaser 
--   FOREIGN KEY (created_by_purchaser_id) REFERENCES users(id) ON DELETE SET NULL;

-- Users table foreign key (purchaser_id references users.id)
-- ALTER TABLE users ADD CONSTRAINT fk_users_purchaser 
--   FOREIGN KEY (purchaser_id) REFERENCES users(id) ON DELETE SET NULL;


-- ============================================================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
-- Enable RLS for security (optional but recommended)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE price_history ENABLE ROW LEVEL SECURITY;

-- Example RLS policies (customize based on your authentication setup)

-- Users: Users can view their own profile
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid()::text = user_id);

-- Products: Suppliers can view/edit their own products
CREATE POLICY "Suppliers can view own products" ON products
  FOR SELECT USING (auth.uid()::text = fk_owned_by);

CREATE POLICY "Suppliers can insert own products" ON products
  FOR INSERT WITH CHECK (auth.uid()::text = fk_owned_by);

CREATE POLICY "Suppliers can update own products" ON products
  FOR UPDATE USING (auth.uid()::text = fk_owned_by);

-- Orders: Suppliers can view their own orders
CREATE POLICY "Suppliers can view own orders" ON orders
  FOR SELECT USING (auth.uid()::text = vendor_id);

-- Price history: Suppliers can view their own price history
CREATE POLICY "Suppliers can view own price history" ON price_history
  FOR SELECT USING (auth.uid()::text = created_by_supplier_id);

-- Note: Add more policies based on your specific requirements
-- For admin/agent access, you may need service role or custom policies


-- ============================================================================
-- 7. FUNCTIONS AND TRIGGERS
-- ============================================================================
-- Utility functions and triggers for automation
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- Function to get product count for a supplier
CREATE OR REPLACE FUNCTION get_product_count_for_supplier(supplier_user_id TEXT)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(DISTINCT product_id)
    FROM products
    WHERE fk_owned_by = supplier_user_id
  );
END;
$$ LANGUAGE plpgsql;


-- Function to get pending price change count
CREATE OR REPLACE FUNCTION get_pending_price_change_count()
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)
    FROM price_history
    WHERE status = 'pending'
  );
END;
$$ LANGUAGE plpgsql;


-- ============================================================================
-- 8. VIEWS (Optional - for reporting)
-- ============================================================================
-- Create useful views for reporting and analytics
-- ============================================================================

-- View: Product summary with variant count
CREATE OR REPLACE VIEW product_summary AS
SELECT 
  product_id,
  product_title,
  fk_owned_by,
  status,
  COUNT(*) as variant_count,
  MIN(variant_selling_price) as min_price,
  MAX(variant_selling_price) as max_price,
  SUM(variant_stock) as total_stock,
  MAX(created_at) as created_at,
  MAX(updated_at) as updated_at
FROM products
GROUP BY product_id, product_title, fk_owned_by, status;

-- View: Order statistics by supplier
CREATE OR REPLACE VIEW supplier_order_stats AS
SELECT 
  vendor_id,
  COUNT(*) as total_orders,
  COUNT(CASE WHEN status ILIKE '%delivered%' THEN 1 END) as delivered_orders,
  COUNT(CASE WHEN status ILIKE '%pending%' THEN 1 END) as pending_orders,
  COUNT(CASE WHEN status ILIKE '%return%' THEN 1 END) as returned_orders,
  SUM(CASE WHEN status ILIKE '%delivered%' THEN supplier_selling_price ELSE 0 END) as total_revenue
FROM orders
GROUP BY vendor_id;

-- View: Pending price change requests
CREATE OR REPLACE VIEW pending_price_changes AS
SELECT 
  ph.id,
  ph.product_id,
  ph.variant_id,
  p.product_title,
  p.size,
  p.color,
  p.company_sku,
  ph.previous_price,
  ph.updated_price,
  (ph.updated_price - ph.previous_price) as price_difference,
  ROUND(((ph.updated_price - ph.previous_price) / ph.previous_price * 100)::numeric, 2) as price_change_percent,
  ph.created_by_supplier_id,
  ph.created_at,
  ph.status
FROM price_history ph
LEFT JOIN products p ON ph.variant_id = p.variant_id
WHERE ph.status = 'pending'
ORDER BY ph.created_at DESC;


-- ============================================================================
-- SETUP COMPLETE
-- ============================================================================
-- All essential tables, indexes, constraints, and utilities have been created
-- 
-- Next steps:
-- 1. Update your frontend .env.local with the new Supabase URL and API key
-- 2. Update your backend .env.local with the new Supabase credentials
-- 3. Migrate existing data from old database (if needed)
-- 4. Test all functionality with the new database
-- ============================================================================

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'DATABASE SETUP COMPLETE!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'Core Tables created (4):';
  RAISE NOTICE '  1. users (with purchaser_id column for supplier-purchaser relationships)';
  RAISE NOTICE '  2. products';
  RAISE NOTICE '  3. orders';
  RAISE NOTICE '  4. price_history';
  RAISE NOTICE '';
  RAISE NOTICE 'Views created (3):';
  RAISE NOTICE '  - product_summary';
  RAISE NOTICE '  - supplier_order_stats';
  RAISE NOTICE '  - pending_price_changes';
  RAISE NOTICE '';
  RAISE NOTICE 'Key Points:';
  RAISE NOTICE '  - users.purchaser_id: Suppliers reference their purchaser (users.id)';
  RAISE NOTICE '  - users.id: Auto-increment ID used in price_history and purchaser_id';
  RAISE NOTICE '  - users.user_id: Friendly ID (SUP001, PUR001) used in products/orders';
  RAISE NOTICE '  - NO supplier_purchaser junction table (relationship in users table)';
  RAISE NOTICE '';
  RAISE NOTICE 'Next steps:';
  RAISE NOTICE '  1. Update environment variables with new database credentials';
  RAISE NOTICE '  2. Migrate existing data (if needed)';
  RAISE NOTICE '  3. Test all functionality';
  RAISE NOTICE '============================================================================';
END $$;
