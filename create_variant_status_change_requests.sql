-- ============================================================================
-- VARIANT STATUS CHANGE REQUESTS (approval workflow)
-- ============================================================================
-- Purpose:
-- - Store pending requests to change variant availability status
--   (active <-> inactive) initiated by Supplier/Admin/Purchaser.
-- - Agent approves/rejects in Approvals tab.
-- - Live variant status is updated only after approval.
-- ============================================================================

CREATE TABLE IF NOT EXISTS variant_status_change_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id bigint NOT NULL,
  variant_id bigint NOT NULL,
  request_scope text NOT NULL DEFAULT 'variant',
  previous_active boolean NOT NULL,
  updated_active boolean NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by_supplier_id text,
  created_by_purchaser_id bigint,
  status text NOT NULL DEFAULT 'pending',
  reviewed_at timestamptz,
  reviewed_by text,
  CONSTRAINT variant_status_change_requests_status_check
    CHECK (status IN ('pending', 'approved', 'rejected')),
  CONSTRAINT variant_status_change_requests_scope_check
    CHECK (request_scope IN ('variant', 'product'))
);

CREATE INDEX IF NOT EXISTS idx_variant_status_change_requests_status
  ON variant_status_change_requests(status);

CREATE INDEX IF NOT EXISTS idx_variant_status_change_requests_variant
  ON variant_status_change_requests(variant_id);

COMMENT ON TABLE variant_status_change_requests IS
'Approval requests for variant active/inactive changes.';

ALTER TABLE variant_status_change_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable read for authenticated users on variant_status_change_requests" ON variant_status_change_requests;
DROP POLICY IF EXISTS "Enable insert for authenticated users on variant_status_change_requests" ON variant_status_change_requests;
DROP POLICY IF EXISTS "Enable update for authenticated users on variant_status_change_requests" ON variant_status_change_requests;
DROP POLICY IF EXISTS "Enable read for anon users on variant_status_change_requests" ON variant_status_change_requests;
DROP POLICY IF EXISTS "Enable insert for anon users on variant_status_change_requests" ON variant_status_change_requests;
DROP POLICY IF EXISTS "Enable update for anon users on variant_status_change_requests" ON variant_status_change_requests;

CREATE POLICY "Enable read for authenticated users on variant_status_change_requests"
  ON variant_status_change_requests FOR SELECT TO authenticated USING (true);
CREATE POLICY "Enable insert for authenticated users on variant_status_change_requests"
  ON variant_status_change_requests FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Enable update for authenticated users on variant_status_change_requests"
  ON variant_status_change_requests FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "Enable read for anon users on variant_status_change_requests"
  ON variant_status_change_requests FOR SELECT TO anon USING (true);
CREATE POLICY "Enable insert for anon users on variant_status_change_requests"
  ON variant_status_change_requests FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "Enable update for anon users on variant_status_change_requests"
  ON variant_status_change_requests FOR UPDATE TO anon USING (true) WITH CHECK (true);

