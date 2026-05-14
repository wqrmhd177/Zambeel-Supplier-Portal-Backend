-- ============================================================
-- Add 'cancelled' as a valid status for product availability requests.
-- ============================================================

ALTER TABLE product_availability_requests
  DROP CONSTRAINT IF EXISTS product_availability_requests_status_check;

ALTER TABLE product_availability_requests
  ADD CONSTRAINT product_availability_requests_status_check
  CHECK (status IN ('pending', 'delayed', 'completed', 'cancelled'));
