-- Make legacy products.variant_id column nullable so new variant system can work
-- without requiring a variant_id value on insert.
--
-- This is safe because:
-- - New products store their variants in the product_variants table.
-- - The app no longer relies on products.variant_id for new data.
-- - Existing legacy rows keep their current variant_id values.

ALTER TABLE products
  ALTER COLUMN variant_id DROP NOT NULL;

-- Optional: leave the default as NULL (no default clause needed).

