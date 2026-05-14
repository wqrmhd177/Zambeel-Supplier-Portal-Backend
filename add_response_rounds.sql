-- ============================================================
-- Add round_number to product_availability_responses so that
-- response history is preserved across multiple search rounds.
-- Update submit_availability_response RPC to keep history.
-- Add request_alternative_search RPC to reopen a request.
-- ============================================================

-- 1. Add round tracking column
ALTER TABLE product_availability_responses
  ADD COLUMN IF NOT EXISTS round_number integer NOT NULL DEFAULT 1;

CREATE INDEX IF NOT EXISTS idx_par_round
  ON product_availability_responses (request_id, round_number DESC);

-- 2. Update the submit RPC: insert with next round_number instead of deleting old response
CREATE OR REPLACE FUNCTION submit_availability_response(
  p_request_id             uuid,
  p_responded_by_user_id   text,
  p_availability           text,
  p_stock_status           text,
  p_single_unit_price      numeric  DEFAULT NULL,
  p_bulk_unit_price        numeric  DEFAULT NULL,
  p_response_images        text[]   DEFAULT ARRAY[]::text[],
  p_remarks                text     DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_round integer;
BEGIN
  -- Calculate the next round number for this request
  SELECT COALESCE(MAX(round_number), 0) + 1
    INTO v_round
    FROM product_availability_responses
   WHERE request_id = p_request_id;

  -- Insert the new response (old responses are preserved as history)
  INSERT INTO product_availability_responses (
    request_id,
    responded_by_user_id,
    availability,
    stock_status,
    single_unit_price,
    bulk_unit_price,
    response_images,
    remarks,
    round_number
  ) VALUES (
    p_request_id,
    p_responded_by_user_id,
    p_availability,
    p_stock_status,
    p_single_unit_price,
    p_bulk_unit_price,
    p_response_images,
    p_remarks,
    v_round
  );

  -- Mark the request as completed
  UPDATE product_availability_requests
  SET
    assignment_status = 'completed',
    responded_at      = NOW(),
    status            = 'completed',
    updated_at        = NOW()
  WHERE id = p_request_id;

  RETURN jsonb_build_object('success', true, 'round', v_round);
END;
$$;

-- 3. New RPC: reopen a completed request for a second-round alternative search
CREATE OR REPLACE FUNCTION request_alternative_search(
  p_request_id  uuid,
  p_new_remarks text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE product_availability_requests
  SET
    assignment_status = 'pending',
    status            = 'pending',
    remarks           = p_new_remarks,
    responded_at      = NULL,
    updated_at        = NOW()
  WHERE id = p_request_id;

  RETURN jsonb_build_object('success', true);
END;
$$;
