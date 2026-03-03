-- ============================================================================
-- ADD ALL MISSING PAYMENT-RELATED COLUMNS TO USERS TABLE
-- ============================================================================
-- This adds all payment method columns that the onboarding form uses
-- ============================================================================

-- Add all missing payment columns
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS binance_wallet TEXT,
ADD COLUMN IF NOT EXISTS paypal_email TEXT,
ADD COLUMN IF NOT EXISTS paypal_account_name TEXT,
ADD COLUMN IF NOT EXISTS exchange_name TEXT,
ADD COLUMN IF NOT EXISTS exchange_account_name TEXT,
ADD COLUMN IF NOT EXISTS exchange_id TEXT,
ADD COLUMN IF NOT EXISTS exchange_country TEXT,
ADD COLUMN IF NOT EXISTS payment_method TEXT,
ADD COLUMN IF NOT EXISTS cnic TEXT,
ADD COLUMN IF NOT EXISTS pickup_address TEXT,
ADD COLUMN IF NOT EXISTS return_address TEXT,
ADD COLUMN IF NOT EXISTS return_city TEXT,
ADD COLUMN IF NOT EXISTS whatsapp_phone_number TEXT,
ADD COLUMN IF NOT EXISTS supplier_type TEXT,
ADD COLUMN IF NOT EXISTS shop_name TEXT,
ADD COLUMN IF NOT EXISTS stock_location_country TEXT;

-- Add comments for payment columns
COMMENT ON COLUMN users.binance_wallet IS 'Binance wallet address for crypto payments';
COMMENT ON COLUMN users.paypal_email IS 'PayPal account email';
COMMENT ON COLUMN users.paypal_account_name IS 'PayPal account holder name';
COMMENT ON COLUMN users.exchange_name IS 'Money exchange service name';
COMMENT ON COLUMN users.exchange_account_name IS 'Exchange account holder name';
COMMENT ON COLUMN users.exchange_id IS 'Exchange account ID/number';
COMMENT ON COLUMN users.exchange_country IS 'Exchange service country';
COMMENT ON COLUMN users.payment_method IS 'Preferred payment method (Bank Account, PayPal, Exchange, Binance)';

-- Add comments for supplier info columns
COMMENT ON COLUMN users.cnic IS 'National ID/CNIC number';
COMMENT ON COLUMN users.pickup_address IS 'Product pickup address';
COMMENT ON COLUMN users.return_address IS 'Return/exchange address';
COMMENT ON COLUMN users.return_city IS 'Return/exchange city';
COMMENT ON COLUMN users.whatsapp_phone_number IS 'WhatsApp contact number';
COMMENT ON COLUMN users.supplier_type IS 'Type of supplier (Manufacturer, Wholesaler, etc.)';
COMMENT ON COLUMN users.shop_name IS 'Shop/store name on Zambeel';
COMMENT ON COLUMN users.stock_location_country IS 'Country where stock is located';

-- Display success message
DO $$
BEGIN
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'ALL PAYMENT COLUMNS ADDED SUCCESSFULLY!';
  RAISE NOTICE '============================================================================';
  RAISE NOTICE 'Payment method columns added:';
  RAISE NOTICE '  - binance_wallet';
  RAISE NOTICE '  - paypal_email, paypal_account_name';
  RAISE NOTICE '  - exchange_name, exchange_account_name, exchange_id, exchange_country';
  RAISE NOTICE '  - payment_method';
  RAISE NOTICE '';
  RAISE NOTICE 'Supplier information columns added:';
  RAISE NOTICE '  - cnic (National ID)';
  RAISE NOTICE '  - pickup_address, return_address, return_city';
  RAISE NOTICE '  - whatsapp_phone_number';
  RAISE NOTICE '  - supplier_type, shop_name, stock_location_country';
  RAISE NOTICE '============================================================================';
END $$;
