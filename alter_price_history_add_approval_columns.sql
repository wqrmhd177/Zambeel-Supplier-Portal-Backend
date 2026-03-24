-- Adds approval workflow columns to price_history.
-- Run this in your Supabase SQL editor.

ALTER TABLE price_history
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'pending';

ALTER TABLE price_history
  ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ;

ALTER TABLE price_history
  ADD COLUMN IF NOT EXISTS reviewed_by TEXT;

ALTER TABLE price_history
  DROP CONSTRAINT IF EXISTS check_price_history_status;

ALTER TABLE price_history
  ADD CONSTRAINT check_price_history_status
  CHECK (status IN ('pending', 'approved', 'rejected'));

