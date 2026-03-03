# Price Change Approval Workflow - Setup Guide

## Overview

This document describes the price change approval workflow that has been implemented. All price changes now require approval from the listing team (agents) before being applied to products.

## Architecture

The approval workflow uses the existing `price_history` table with additional columns to track approval status. This eliminates the need for a separate approval requests table and keeps all price-related data in one place.

## Database Changes

### 1. Run the Migration Script

Execute the following SQL script in your Supabase SQL Editor:

```sql
-- File: backend/add_approval_columns_to_price_history.sql
```

This script:
- Adds `status` column (TEXT): 'pending', 'approved', or 'rejected'
- Adds `reviewed_at` column (TIMESTAMPTZ): When the request was reviewed
- Adds `reviewed_by` column (TEXT): Agent's user_id who reviewed it
- Creates an index on `status` for fast filtering
- Backfills existing records with status='approved'

### 2. Verify the Migration

After running the script, verify the columns exist:

```sql
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'price_history';
```

You should see:
- `status` (text)
- `reviewed_at` (timestamp with time zone)
- `reviewed_by` (text)

## How It Works

### For Suppliers (Price Change Request)

1. **Edit Product Price**: When a supplier edits a product price in `/products/edit/[id]`:
   - The system detects the price change
   - Creates a `price_history` entry with `status='pending'`
   - **Does NOT update** the `products` table
   - Shows message: "Request sent for approval! Other changes saved successfully."

2. **Products List**: In `/products`:
   - Products with pending price changes show: `PKR 100 → 150` with a yellow "Pending Approval" badge
   - Non-price changes (title, images, stock) are saved immediately

### For Agents (Listing Team)

1. **Access Approvals Page**: Agents can access `/approvals` from the sidebar menu

2. **Review Requests**: The approvals page shows:
   - Product title and variant details
   - Old price → New price with percentage change
   - Requested by (supplier ID)
   - Request date (time ago format)
   - Approve/Reject buttons

3. **Approve Request**:
   - Updates `products.variant_selling_price` with the new price
   - Sets `price_history.status = 'approved'`
   - Records `reviewed_at` and `reviewed_by`
   - Shows success message

4. **Reject Request**:
   - Sets `price_history.status = 'rejected'`
   - Does NOT update the product price
   - Records `reviewed_at` and `reviewed_by`
   - Shows success message

## Frontend Components

### Modified Files

1. **`frontend/src/lib/priceHistoryHelpers.ts`**
   - Updated `PriceHistoryEntry` interface with approval fields
   - Updated `createPriceHistoryEntry()` to accept `status` parameter (defaults to 'pending')
   - Added `fetchPendingPriceRequests()` - Get all pending requests
   - Added `fetchRequestsByStatus()` - Filter by status
   - Added `approvePriceChange()` - Approve and update product
   - Added `rejectPriceChange()` - Reject without updating product
   - Added `getPendingRequestCount()` - For notification badges

2. **`frontend/src/app/products/edit/[id]/page.tsx`**
   - Detects price changes by comparing with `originalPrices`
   - Creates pending entries instead of updating prices directly
   - Keeps old price in products table when price changes
   - Shows appropriate success message based on pending changes

3. **`frontend/src/app/approvals/page.tsx`** (NEW)
   - Dedicated page for agents to review price change requests
   - Filter by: Pending, Approved, Rejected, All
   - Shows product details with price comparison
   - Approve/Reject buttons with loading states
   - Real-time success/error messages

4. **`frontend/src/components/Sidebar.tsx`**
   - Added "Approvals" menu item for agents
   - Uses CheckCircle icon

5. **`frontend/src/app/products/page.tsx`**
   - Fetches pending price changes on load
   - Shows "Pending Approval" badge for products with pending changes
   - Displays old → new price format

## User Roles

### Supplier (role: 'supplier')
- Can edit product prices
- Price changes create pending requests
- Can see pending badges on their products

### Agent (role: 'agent')
- Can access Approvals page
- Can approve/reject price changes
- Only sees Listings and Approvals in sidebar

### Admin (role: 'admin')
- Full access to all features
- Can see all products and approvals

### Purchaser (role: 'purchaser')
- Can view products from their suppliers
- Cannot approve price changes (agents only)

## Testing Checklist

- [x] Add approval columns to price_history table
- [x] Backfill existing records with status='approved'
- [ ] Test: Edit product price → creates pending entry
- [ ] Test: Product price NOT updated in products table
- [ ] Test: Success message shows "Request Sent for Approval"
- [ ] Test: Non-price changes (title, stock) save immediately
- [ ] Test: Agent sees pending request in Approvals page
- [ ] Test: Agent approves → products table updated, status='approved'
- [ ] Test: Agent rejects → products table NOT updated, status='rejected'
- [ ] Test: Products list shows pending badge with old → new price
- [ ] Test: Sidebar shows Approvals menu for agents only

## Database Schema

### price_history Table (Updated)

```sql
CREATE TABLE price_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id BIGINT NOT NULL,
  variant_id BIGINT NOT NULL,
  previous_price DECIMAL(10, 2) NOT NULL,
  updated_price DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by_supplier_id TEXT,
  created_by_purchaser_id INTEGER,
  status TEXT NOT NULL DEFAULT 'pending',           -- NEW
  reviewed_at TIMESTAMPTZ,                          -- NEW
  reviewed_by TEXT,                                 -- NEW
  CONSTRAINT check_status_valid CHECK (status IN ('pending', 'approved', 'rejected'))
);

CREATE INDEX idx_price_history_status ON price_history(status);
```

## API Endpoints Used

All operations use Supabase client-side SDK:

- `supabase.from('price_history').insert()` - Create pending request
- `supabase.from('price_history').select().eq('status', 'pending')` - Fetch pending
- `supabase.from('price_history').update()` - Approve/reject
- `supabase.from('products').update()` - Update price on approval

## Future Enhancements

1. **Email Notifications**: Notify agents when new requests are created
2. **Notification Badge**: Show count of pending requests in sidebar
3. **Bulk Actions**: Approve/reject multiple requests at once
4. **Review Notes**: Add a notes field for agents to explain rejection reasons
5. **Auto-approval**: Option for trusted suppliers to bypass approval
6. **Price History View**: Show full price history on product details page

## Troubleshooting

### Issue: Pending requests not showing in Approvals page

**Solution**: Check that:
1. The migration script was run successfully
2. The agent user has `role='agent'` in the users table
3. The price_history entries have `status='pending'`

### Issue: Price still updates immediately

**Solution**: Check that:
1. The product edit page is using the updated code
2. The `createPriceHistoryEntry()` is being called with `status='pending'`
3. The products table update is using the old price when price changes

### Issue: Approved changes not reflecting in products

**Solution**: Check that:
1. The `approvePriceChange()` function is updating the products table
2. The variant_id matches between price_history and products
3. No database constraints are preventing the update

## Support

For issues or questions, check:
1. Browser console for JavaScript errors
2. Supabase logs for database errors
3. Network tab for failed API calls

## Summary

The approval workflow ensures that all price changes are reviewed by the listing team before being applied. This provides:
- **Quality Control**: Prevent pricing errors
- **Audit Trail**: Complete history of all price changes and approvals
- **Role Separation**: Suppliers request, agents approve
- **Transparency**: Clear status tracking (pending/approved/rejected)

