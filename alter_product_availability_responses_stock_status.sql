-- Update purchaser response schema for new stock status behavior:
-- - Remove "bulk" option
-- - Add "bulk_limited_both"
-- - Allow optional single/bulk prices when stock_status = bulk_limited_both

ALTER TABLE product_availability_responses
  ALTER COLUMN single_unit_price DROP NOT NULL;

ALTER TABLE product_availability_responses
  DROP CONSTRAINT IF EXISTS product_availability_responses_stock_status_check;

ALTER TABLE product_availability_responses
  ADD CONSTRAINT product_availability_responses_stock_status_check
  CHECK (stock_status IN ('limited', 'on_demand', 'bulk_limited_both'));

ALTER TABLE product_availability_responses
  DROP CONSTRAINT IF EXISTS product_availability_responses_single_unit_price_check;

ALTER TABLE product_availability_responses
  ADD CONSTRAINT product_availability_responses_single_unit_price_check
  CHECK (single_unit_price IS NULL OR single_unit_price >= 0);

ALTER TABLE product_availability_responses
  DROP CONSTRAINT IF EXISTS product_availability_responses_bulk_required_check;

ALTER TABLE product_availability_responses
  ADD CONSTRAINT product_availability_responses_bulk_required_check
  CHECK (
    availability = 'not_available'
    OR (stock_status = 'bulk_limited_both')
    OR (stock_status <> 'bulk_limited_both' AND single_unit_price IS NOT NULL)
  );

