-- Step 1: Check current status of all suppliers
-- Run this first to see what's wrong
SELECT 
  user_id,
  email,
  shop_name_on_zambeel,
  shop_name,
  archived,
  account_approval,
  role
FROM users
WHERE role = 'supplier'
ORDER BY user_id;

-- Step 2: Fix all suppliers to make them "active"
-- Run this to make all suppliers visible in the dropdown
UPDATE users
SET 
  archived = false,
  account_approval = 'Approved'
WHERE role = 'supplier';

-- Step 3: Verify the fix
-- Run this to confirm all suppliers are now active
SELECT 
  user_id,
  email,
  shop_name_on_zambeel,
  archived,
  account_approval
FROM users
WHERE role = 'supplier'
ORDER BY user_id;
