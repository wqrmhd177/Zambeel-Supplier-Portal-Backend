-- Add approval workflow columns to price_history table
-- This migration adds status tracking for price change approvals

-- Add status column (pending, approved, rejected)
ALTER TABLE price_history 
ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'approved';

-- Add reviewed_at column
ALTER TABLE price_history 
ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ;

-- Add reviewed_by column (agent who approved/rejected)
ALTER TABLE price_history 
ADD COLUMN IF NOT EXISTS reviewed_by TEXT;

-- Add constraint for valid status values
ALTER TABLE price_history 
ADD CONSTRAINT check_status_valid 
CHECK (status IN ('pending', 'approved', 'rejected'));

-- Create index for filtering by status
CREATE INDEX IF NOT EXISTS idx_price_history_status ON price_history(status);

-- Add comments for documentation
COMMENT ON COLUMN price_history.status IS 'Approval status: pending, approved, or rejected';
COMMENT ON COLUMN price_history.reviewed_at IS 'When the price change was reviewed by agent';
COMMENT ON COLUMN price_history.reviewed_by IS 'Agent user_id who reviewed the request';

-- Backfill existing records (they were already applied, so mark as approved)
UPDATE price_history 
SET status = 'approved', 
    reviewed_at = created_at 
WHERE status = 'approved' AND reviewed_at IS NULL;

