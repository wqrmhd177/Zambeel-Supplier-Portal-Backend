-- Fix: allow null single_unit_price when availability = 'not_available'
--
-- The previous constraint required single_unit_price IS NOT NULL whenever
-- stock_status <> 'bulk_limited_both'. But for "Not Available" responses,
-- the app sets stock_status = 'on_demand' and single_unit_price = null,
-- which violated the constraint.
--
-- Run this in the Supabase SQL Editor.

ALTER TABLE product_availability_responses
  DROP CONSTRAINT IF EXISTS product_availability_responses_bulk_required_check;

ALTER TABLE product_availability_responses
  ADD CONSTRAINT product_availability_responses_bulk_required_check
  CHECK (
    availability = 'not_available'
    OR (stock_status = 'bulk_limited_both')
    OR (stock_status <> 'bulk_limited_both' AND single_unit_price IS NOT NULL)
  );
