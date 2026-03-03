-- ============================================================================
-- AUTO-GENERATE USER ID TRIGGER
-- ============================================================================
-- This script creates a trigger to automatically generate sequential user_id
-- Format: Simple numbers 1, 2, 3, 4, 5...
-- ============================================================================

-- Step 1: Make user_id nullable (so trigger can set it)
ALTER TABLE users ALTER COLUMN user_id DROP NOT NULL;

-- Step 2: Create function to generate sequential user_id
CREATE OR REPLACE FUNCTION generate_user_id()
RETURNS TRIGGER AS $$
DECLARE
  next_id INTEGER;
BEGIN
  -- Only generate if user_id is not provided
  IF NEW.user_id IS NULL OR NEW.user_id = '' THEN
    -- Get the highest existing numeric user_id and add 1
    SELECT COALESCE(MAX(CAST(user_id AS INTEGER)), 0) + 1 
    INTO next_id
    FROM users
    WHERE user_id ~ '^[0-9]+$';  -- Only count numeric user_ids
    
    -- Set the new user_id
    NEW.user_id := next_id::TEXT;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 3: Create trigger on users table
DROP TRIGGER IF EXISTS trigger_generate_user_id ON users;
CREATE TRIGGER trigger_generate_user_id
  BEFORE INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION generate_user_id();

-- ============================================================================
-- TESTING
-- ============================================================================
-- Test by inserting a user without user_id:
-- INSERT INTO users (email, password, role) VALUES ('test@example.com', 'password123', 'supplier');
-- The user_id should be auto-generated as '1', '2', '3', etc.
-- ============================================================================

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'USER ID AUTO-GENERATION SETUP COMPLETE!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'User IDs will now be automatically generated as: 1, 2, 3, 4, 5...';
  RAISE NOTICE '';
  RAISE NOTICE 'How it works:';
  RAISE NOTICE '  - When a new user is created without a user_id, it auto-generates';
  RAISE NOTICE '  - Sequential numbers: 1, 2, 3, 4, 5...';
  RAISE NOTICE '  - If user_id is provided during insert, it uses that instead';
  RAISE NOTICE '';
  RAISE NOTICE 'Test it:';
  RAISE NOTICE '  INSERT INTO users (email, password, role) ';
  RAISE NOTICE '  VALUES (''test@example.com'', ''pass123'', ''supplier'');';
  RAISE NOTICE '============================================================================';
END $$;
