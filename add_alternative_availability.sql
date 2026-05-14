-- ============================================================
-- Add 'alternative' as a valid availability option in responses.
-- ============================================================

ALTER TABLE product_availability_responses
  DROP CONSTRAINT IF EXISTS product_availability_responses_availability_check;

ALTER TABLE product_availability_responses
  ADD CONSTRAINT product_availability_responses_availability_check
  CHECK (availability IN ('available', 'not_available', 'on_demand', 'alternative'));
