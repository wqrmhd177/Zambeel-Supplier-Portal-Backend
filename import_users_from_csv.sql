-- ============================================================================
-- IMPORT USERS FROM CSV FILE
-- ============================================================================
-- Use this as a template to bulk insert users
-- Replace the values with your actual data from CSV
-- ============================================================================

-- Example: Insert multiple users at once
INSERT INTO users (
  email,
  password,
  role,
  full_name,
  owner_name,
  country,
  city,
  phone_number,
  whatsapp_phone_number,
  onboarded,
  archived,
  account_approval,
  created_at,
  updated_at
) VALUES
  -- Admin User
  (
    'admin@zambeel.com',
    'admin123',  -- Note: In production, hash passwords!
    'admin',
    'Admin User',
    'Admin User',
    'Pakistan',
    'Karachi',
    '+923001234567',
    '+923001234567',
    true,
    false,
    'Approved',
    NOW(),
    NOW()
  ),
  -- Supplier User
  (
    'supplier1@zambeel.com',
    'supplier123',
    'supplier',
    'Supplier One',
    'Supplier One',
    'UAE',
    'Dubai',
    '+971501234567',
    '+971501234567',
    false,
    false,
    'Wait',
    NOW(),
    NOW()
  ),
  -- Add more users here following the same pattern
  (
    'supplier2@zambeel.com',
    'pass456',
    'supplier',
    'Supplier Two',
    'Supplier Two',
    'Saudi Arabia',
    'Riyadh',
    '+966501234567',
    '+966501234567',
    false,
    false,
    'Wait',
    NOW(),
    NOW()
  )
ON CONFLICT (email) DO NOTHING;  -- Skip if email already exists

-- Verify the import
SELECT user_id, email, role, full_name, country, account_approval 
FROM users 
ORDER BY created_at DESC 
LIMIT 10;
