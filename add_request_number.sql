-- Add a human-readable auto-incrementing request number to product_availability_requests.
--
-- This gives every request a short numeric ID (e.g. #1, #2, …) that users can
-- reference and search by, in addition to the internal UUID.
--
-- Run this in the Supabase SQL Editor.

-- Create the sequence (skip if it already exists)
CREATE SEQUENCE IF NOT EXISTS product_availability_requests_request_number_seq;

-- Add the column (SERIAL-equivalent using the sequence)
ALTER TABLE product_availability_requests
  ADD COLUMN IF NOT EXISTS request_number INTEGER
    NOT NULL
    DEFAULT nextval('product_availability_requests_request_number_seq');

-- Backfill existing rows that have no request_number yet
-- (rows added before this migration will receive sequential numbers)
DO $$
DECLARE
  rec RECORD;
  seq_val INTEGER;
BEGIN
  FOR rec IN
    SELECT id FROM product_availability_requests
    WHERE request_number IS NULL OR request_number = 0
    ORDER BY created_at ASC
  LOOP
    seq_val := nextval('product_availability_requests_request_number_seq');
    UPDATE product_availability_requests
      SET request_number = seq_val
    WHERE id = rec.id;
  END LOOP;
END $$;

-- Make request_number unique and indexed for fast lookups
CREATE UNIQUE INDEX IF NOT EXISTS product_availability_requests_request_number_idx
  ON product_availability_requests (request_number);
