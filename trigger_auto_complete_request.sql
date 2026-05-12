-- Auto-complete product availability requests via a database trigger.
--
-- Problem: Purchaser/agent roles cannot UPDATE product_availability_requests
-- due to RLS policies, so the application-level status update after a
-- purchaser submits a response silently fails.
--
-- Solution: A SECURITY DEFINER trigger function runs as the table owner
-- (bypassing RLS) and automatically marks a request as 'completed' whenever
-- all its assigned-purchaser assignments are done.
--
-- Run this in the Supabase SQL Editor.

CREATE OR REPLACE FUNCTION fn_sync_request_completion()
RETURNS TRIGGER AS $$
DECLARE
  v_total_assigned  INTEGER;
  v_total_completed INTEGER;
BEGIN
  -- Count only assignments that have an actual purchaser (null = no mapping)
  SELECT
    COUNT(*)        FILTER (WHERE assigned_purchaser_user_id IS NOT NULL),
    COUNT(*)        FILTER (WHERE assigned_purchaser_user_id IS NOT NULL
                               AND assignment_status = 'completed')
  INTO v_total_assigned, v_total_completed
  FROM product_availability_request_markets
  WHERE request_id = NEW.request_id;

  -- If every responsible assignment is done, mark the parent request completed
  IF v_total_assigned > 0 AND v_total_assigned = v_total_completed THEN
    UPDATE product_availability_requests
    SET    status     = 'completed',
           updated_at = NOW()
    WHERE  id         = NEW.request_id
      AND  status    <> 'completed';   -- avoid unnecessary writes
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop old trigger if it exists, then recreate
DROP TRIGGER IF EXISTS trg_auto_complete_request
  ON product_availability_request_markets;

CREATE TRIGGER trg_auto_complete_request
  AFTER INSERT OR UPDATE OF assignment_status
  ON product_availability_request_markets
  FOR EACH ROW
  EXECUTE FUNCTION fn_sync_request_completion();
