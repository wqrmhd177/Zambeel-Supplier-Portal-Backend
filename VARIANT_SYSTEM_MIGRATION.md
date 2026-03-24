# Product Variants System Migration

## Overview

This migration creates a flexible Shopify-style variant system for products, replacing the fixed size/color model with customizable options.

## What's Created

### Database Changes

1. **New columns on `products` table:**
   - `options` (jsonb) - Stores variant option definitions: `[{ name: "Color", values: ["Red","Blue"] }, ...]`
   - `has_variants` (boolean) - Quick flag for products with variants

2. **New `product_variants` table:**
   - `variant_id` (bigserial, PK) - Unique variant identifier
   - `product_id` (bigint, FK) - Parent product reference
   - `option_values` (jsonb) - Variant combination: `{"Color": "Red", "Size": "M"}`
   - `sku` (text) - Variant SKU
   - `price` (numeric) - Variant price
   - `stock` (integer) - Variant stock
   - `image` (jsonb) - Variant images as JSON array
   - `active` (boolean) - Whether variant is available for sale
   - `created_at`, `updated_at` (timestamptz)

3. **Indexes:**
   - `idx_product_variants_product_id` on `product_id`
   - `idx_product_variants_product_active` on `(product_id, active)`
   - `idx_product_variants_sku` on `sku` (where not null)

4. **RLS Policies:**
   - Read access for all authenticated users
   - Insert/update/delete for authenticated users

## How to Run

### Option 1: Supabase SQL Editor (Recommended)

1. Open your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Create a new query
4. Copy and paste the contents of `create_product_variants_table.sql`
5. Click **Run**
6. Verify the output shows success messages

### Option 2: Supabase CLI

```bash
supabase db push --sql-file create_product_variants_table.sql
```

## Verification

After running the migration, verify in Supabase:

1. **Check `products` table:**
   - Should have new columns: `options`, `has_variants`

2. **Check `product_variants` table:**
   - Should exist with all columns listed above
   - Should have indexes and RLS policies enabled

3. **Test insert:**
   ```sql
   -- Test inserting a variant
   INSERT INTO product_variants (product_id, option_values, price, stock, active)
   VALUES (1, '{"Color": "Red", "Size": "M"}'::jsonb, 2500, 10, true);
   ```

## Next Steps

After running this migration:

1. ✅ Database schema is ready
2. 🔄 Update frontend to use new variant system
3. 🔄 Migrate existing products (optional, can be done later)

## Rollback (if needed)

To rollback this migration:

```sql
-- Drop product_variants table
DROP TABLE IF EXISTS product_variants CASCADE;

-- Remove columns from products
ALTER TABLE products DROP COLUMN IF EXISTS options;
ALTER TABLE products DROP COLUMN IF EXISTS has_variants;

-- Drop trigger function
DROP FUNCTION IF EXISTS update_product_variants_updated_at() CASCADE;
```
