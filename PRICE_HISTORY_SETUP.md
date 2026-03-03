# Price History Setup Guide

## Overview

Simple price history tracking system that connects **frontend directly to Supabase**.
No backend scripts needed - all operations happen in real-time from the UI.

---

## Step 1: Create the Table

1. Open your **Supabase Dashboard**
2. Go to **SQL Editor**
3. Copy the contents of `backend/create_price_history_table.sql`
4. Paste and click **Run**

**Expected Result:**
```
Success. No rows returned
```

---

## Step 2: Verify the Table

Run this query in Supabase SQL Editor:

```sql
-- Check table structure
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'price_history';
```

**Expected columns:**
- `id` (uuid)
- `product_id` (bigint)
- `variant_id` (bigint)
- `previous_price` (numeric)
- `updated_price` (numeric)
- `created_at` (timestamp with time zone)
- `created_by_user_id` (text)
- `created_by_purchaser_id` (integer)

---

## Step 3: Test the Table

```sql
-- Insert a test entry
INSERT INTO price_history (
  product_id, variant_id, 
  previous_price, updated_price,
  created_by_user_id
) VALUES (
  1, 1, 
  1000.00, 1200.00,
  'test_user'
);

-- View the entry
SELECT * FROM price_history;

-- Delete test entry
DELETE FROM price_history WHERE created_by_user_id = 'test_user';
```

---

## How It Works

### When a User Changes a Price:

1. **User edits product price in frontend**
2. **Frontend updates `products` table** with new price
3. **Frontend creates price history entry** using helper function:

```typescript
import { createPriceHistoryEntry } from '@/lib/priceHistoryHelpers'

// After updating product price
await createPriceHistoryEntry(
  productId,
  variantId,
  oldPrice,      // Previous price
  newPrice,      // Updated price
  userId,        // User who made the change
  purchaserId    // Optional: if changed by purchaser
)
```

### Data Flow:

```
User changes price in UI
         ↓
Frontend updates products table (Supabase)
         ↓
Frontend creates price_history entry (Supabase)
         ↓
Done! ✅
```

**No backend involved - direct frontend → Supabase connection**

---

## Frontend Helper Functions

All available in `frontend/src/lib/priceHistoryHelpers.ts`:

### Create price history:
```typescript
createPriceHistoryEntry(productId, variantId, oldPrice, newPrice, userId, purchaserId?)
```

### Get variant history:
```typescript
const history = await getVariantPriceHistory(variantId)
// Returns all price changes for a variant, newest first
```

### Get product history:
```typescript
const history = await getProductPriceHistory(productId)
// Returns all price changes for all variants of a product
```

### Get latest change:
```typescript
const latest = await getLatestPriceChange(variantId)
// Returns the most recent price change
```

### Get price statistics:
```typescript
const stats = await getVariantPriceStats(variantId)
// Returns: totalChanges, averageIncrease, averageDecrease, highestPrice, lowestPrice
```

---

## Database Schema

```sql
price_history
├── id (UUID, auto-generated)
├── product_id (BIGINT)
├── variant_id (BIGINT)
├── previous_price (DECIMAL)
├── updated_price (DECIMAL)
├── created_at (TIMESTAMPTZ, auto-generated)
├── created_by_user_id (TEXT)
└── created_by_purchaser_id (INTEGER, nullable)
```

**Constraints:**
- ✅ `previous_price >= 0`
- ✅ `updated_price > 0`
- ✅ `previous_price != updated_price` (price must actually change)

**Indexes:**
- Fast lookups by `variant_id`, `product_id`
- Fast sorting by `created_at`
- Fast filtering by user/purchaser

---

## Example Usage in Product Edit Page

```typescript
// When user saves a price change
const handlePriceUpdate = async () => {
  const oldPrice = currentProduct.variant_selling_price
  const newPrice = formData.sellingPrice
  
  // Step 1: Update products table
  const { error: updateError } = await supabase
    .from('products')
    .update({ variant_selling_price: newPrice })
    .eq('variant_id', variantId)
  
  if (updateError) {
    console.error('Failed to update price:', updateError)
    return
  }
  
  // Step 2: Create price history entry
  await createPriceHistoryEntry(
    productId,
    variantId,
    oldPrice,
    newPrice,
    userId,
    userRole === 'purchaser' ? purchaserId : null
  )
  
  console.log('✅ Price updated and history recorded')
}
```

---

## Viewing Price History

You can add a "Price History" button in your product edit page:

```typescript
const [priceHistory, setPriceHistory] = useState([])
const [showHistory, setShowHistory] = useState(false)

const loadPriceHistory = async () => {
  const history = await getVariantPriceHistory(variantId)
  setPriceHistory(history)
  setShowHistory(true)
}

// In your JSX
<button onClick={loadPriceHistory}>
  View Price History
</button>

{showHistory && (
  <div>
    <h3>Price History</h3>
    {priceHistory.map(entry => (
      <div key={entry.id}>
        <p>Changed from PKR {entry.previous_price} to PKR {entry.updated_price}</p>
        <p>On {new Date(entry.created_at).toLocaleString()}</p>
        <p>By {entry.created_by_user_id}</p>
      </div>
    ))}
  </div>
)}
```

---

## Benefits

✅ **Simple** - No backend scripts to maintain
✅ **Fast** - Direct frontend → Supabase connection
✅ **Real-time** - Changes are instant
✅ **Automatic** - UUID and timestamps auto-generated
✅ **Audit Trail** - Complete history of who changed what and when
✅ **Flexible** - Easy to query and display in UI

---

## Next Steps

After price history is set up:

1. ✅ Integrate into product edit page
2. ✅ Add price history viewer component
3. ✅ Create approval workflow (if needed)
4. ✅ Add price change notifications
5. ✅ Create price analytics dashboard

---

## Troubleshooting

### Table not created?
```sql
-- Check if table exists
SELECT * FROM information_schema.tables WHERE table_name = 'price_history';
```

### Can't insert data?
- Check Supabase RLS policies
- Ensure user has INSERT permission
- Verify column names match exactly

### Need to reset?
```sql
-- Delete all entries (careful!)
DELETE FROM price_history;

-- Or drop and recreate table
DROP TABLE price_history;
-- Then run create_price_history_table.sql again
```

---

That's it! Simple, fast, and frontend-only. 🚀

