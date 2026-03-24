-- Add product/variant scope support for existing databases
ALTER TABLE variant_status_change_requests
  ADD COLUMN IF NOT EXISTS request_scope text NOT NULL DEFAULT 'variant';

ALTER TABLE variant_status_change_requests
  DROP CONSTRAINT IF EXISTS variant_status_change_requests_scope_check;

ALTER TABLE variant_status_change_requests
  ADD CONSTRAINT variant_status_change_requests_scope_check
  CHECK (request_scope IN ('variant', 'product'));

