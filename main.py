import os
import requests
from supabase import create_client, Client
from dotenv import load_dotenv
import time

# Load environment variables (optional - for local development)
# In GitHub Actions, environment variables are set directly
load_dotenv('.env.local')  # Try to load local env file (may not exist in CI)
load_dotenv()  # Fallback to .env if it exists

# Supabase Setup
SUPABASE_URL = os.environ.get("SUPABASE_URL")
SUPABASE_KEY = os.environ.get("SUPABASE_SERVICE_ROLE_KEY") or os.environ.get("SUPABASE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise RuntimeError("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Metabase URL
ORDERS_URL = "https://zambeel.metabaseapp.com/public/question/c3444fcc-451e-4df0-8ab6-cf0c16ec2ea0.json"

# Helpers
def fetch_json(url: str):
    """Fetch JSON data from Metabase."""
    response = requests.get(url)
    response.raise_for_status()
    return response.json()

def chunked(iterable, size=500):
    """Yield successive chunks from iterable."""
    for i in range(0, len(iterable), size):
        yield iterable[i:i + size]

def upsert_with_retry(table, data, max_retries=3):
    """Upsert data with retry logic. Uses composite key (order_id, sku) for duplicate detection."""
    for attempt in range(max_retries):
        try:
            # Supabase upsert() with composite key (order_id, sku)
            # This will update existing records or insert new ones based on the composite unique constraint
            return supabase.table(table).upsert(data, on_conflict="order_id,sku").execute()
        except (TypeError, AttributeError):
            # If on_conflict parameter not supported, fallback to default upsert
            # Supabase will auto-detect the composite unique constraint
            return supabase.table(table).upsert(data).execute()
        except Exception as e:
            if attempt < max_retries - 1:
                print(f"⚠️ Attempt {attempt + 1} failed, retrying...")
                time.sleep(5)
else:
                raise

def build_price_lookup_maps(unique_skus):
    """
    Build lookup maps for SKU->variant_id and variant_id->current_price in batch.
    This is much faster than querying for each order individually.
    
    Returns:
        tuple: (sku_to_variant_map, variant_to_price_map)
    """
    try:
        # Fetch all products for the unique SKUs in one query
        products_response = supabase.table('products') \
            .select('company_sku, variant_id, variant_selling_price') \
            .in_('company_sku', unique_skus) \
            .execute()
        
        sku_to_variant = {}
        variant_to_price = {}
        
        if products_response.data:
            for product in products_response.data:
                sku = product.get('company_sku')
                variant_id = product.get('variant_id')
                price = product.get('variant_selling_price')
                
                if sku and variant_id:
                    # If multiple variants have same SKU, use first one
                    if sku not in sku_to_variant:
                        sku_to_variant[sku] = variant_id
                        variant_to_price[variant_id] = price
        
        return sku_to_variant, variant_to_price
    except Exception as e:
        print(f"⚠️ Error building price lookup maps: {e}")
        return {}, {}

def get_historical_price_batch(sku: str, order_date: str, sku_to_variant: dict, variant_to_price: dict, price_history_cache: dict):
    """
    Get historical price using pre-loaded lookup maps (much faster).
    
    Args:
        sku: Product SKU
        order_date: Order date
        sku_to_variant: Pre-loaded SKU to variant_id map
        variant_to_price: Pre-loaded variant_id to current price map
        price_history_cache: Cache of price history entries
        
    Returns:
        float: Historical price or None
    """
    # Get variant_id from pre-loaded map
    variant_id = sku_to_variant.get(sku)
    if not variant_id:
        return None  # Product not found
    
    current_price = variant_to_price.get(variant_id)
    
    # Check if we have price history for this variant
    if variant_id in price_history_cache:
        # Find most recent approved price before or at order_date
        history_entries = price_history_cache[variant_id]
        for entry in history_entries:
            if entry['created_at'] <= order_date and entry['status'] == 'approved':
                return entry['updated_price']
    
    # No history found, use current price
    return current_price

# Sync Orders
def sync_orders():
    """Sync orders from Metabase to Supabase with historical prices (optimized with batch queries)."""
    print("=" * 60)
    print("Orders Sync Script with Historical Pricing")
    print("=" * 60)
    
    print("Fetching orders from Metabase...")
    orders_data = fetch_json(ORDERS_URL)
    print(f"✅ Fetched {len(orders_data)} orders")
    
    # Fetch existing orders from Supabase to preserve historical prices
    print("Fetching existing orders from Supabase...")
    existing_orders = {}
    try:
        # Fetch ALL orders in batches (Supabase limits to 1000 by default)
        offset = 0
        batch_size = 1000
        total_fetched = 0
        
        while True:
            response = supabase.table('orders') \
                .select('order_id, sku, supplier_selling_price') \
                .range(offset, offset + batch_size - 1) \
                .execute()
            
            if not response.data:
                break
            
            for order in response.data:
                key = (order['order_id'], order['sku'])
                existing_orders[key] = order.get('supplier_selling_price')
            
            total_fetched += len(response.data)
            
            # Break if we got fewer than batch_size (last batch)
            if len(response.data) < batch_size:
                break
            
            offset += batch_size
        
        print(f"✅ Found {len(existing_orders)} existing orders in Supabase (fetched in batches)")
    except Exception as e:
        print(f"⚠️ Error fetching existing orders: {e}")
    
    # First pass: collect all unique SKUs and prepare order rows
    order_rows = []
    skipped = 0
    unique_skus = set()
    orders_needing_price = []

    for row in orders_data:
        order_id = row.get("order_id")
        sku = row.get("sku")
        order_date = row.get("order_date")
        
        # Skip rows without both order_id and sku (required for composite key)
        if not order_id or not sku:
            skipped += 1
                    continue
                
        # Check if this order already has a historical price
        key = (order_id, sku)
        existing_price = existing_orders.get(key)
        
        order_row = {
            "order_id": order_id,
            "sku": sku,
            "vendor_id": row.get("vendor_id"),
            "order_date": order_date,
            "phone": row.get("phone"),
            "country": row.get("country"),
            "title": row.get("title"),
            "quantity": row.get("quantity"),
            "status": row.get("status"),
            "supplier_selling_price": existing_price,  # Preserve existing price
        }
        
        # Only add to lookup list if price doesn't exist
        if existing_price is None and sku:
            unique_skus.add(sku)
            orders_needing_price.append(order_row)
        
        order_rows.append(order_row)

    if skipped > 0:
        print(f"⚠️ Skipped {skipped} orders missing order_id or sku")
    
    orders_with_prices = len(order_rows) - len(orders_needing_price)
    print(f"📊 Summary:")
    print(f"   - {orders_with_prices} orders already have prices (will be preserved)")
    print(f"   - {len(orders_needing_price)} orders need price lookup (new or missing prices)")
    
    # Show which orders are being preserved (if any)
    if orders_with_prices > 0:
        print(f"\n🔒 Preserving prices for {orders_with_prices} existing orders:")
        count = 0
        for order in order_rows:
            if order['supplier_selling_price'] is not None:
                print(f"   Order {order['order_id']} (SKU: {order['sku']}): PKR {order['supplier_selling_price']}")
                count += 1
                if count >= 5:  # Only show first 5
                    if orders_with_prices > 5:
                        print(f"   ... and {orders_with_prices - 5} more")
                    break
    print()
    
    # Only do price lookups if there are orders needing prices
    if orders_needing_price:
        # Build lookup maps in batch (much faster than individual queries)
        print(f"🔍 Building price lookup maps for {len(unique_skus)} unique SKUs...")
        sku_to_variant, variant_to_price = build_price_lookup_maps(list(unique_skus))
        print(f"✅ Found products for {len(sku_to_variant)} SKUs")
        
        # Fetch all price history entries for relevant variants (in batch)
        print(f"📊 Fetching price history...")
        variant_ids = list(sku_to_variant.values())
        price_history_cache = {}
        
        if variant_ids:
            try:
                history_response = supabase.table('price_history') \
                    .select('variant_id, updated_price, created_at, status') \
                    .in_('variant_id', variant_ids) \
                    .eq('status', 'approved') \
                    .order('created_at', desc=True) \
                    .execute()
                
                if history_response.data:
                    # Group by variant_id
                    for entry in history_response.data:
                        variant_id = entry['variant_id']
                        if variant_id not in price_history_cache:
                            price_history_cache[variant_id] = []
                        price_history_cache[variant_id].append(entry)
                    
                    print(f"✅ Loaded {len(history_response.data)} price history entries")
            except Exception as e:
                print(f"⚠️ Error fetching price history: {e}")
        
        # Second pass: populate prices using batch-loaded data (only for orders needing prices)
        price_lookups = 0
        for order in orders_needing_price:
            sku = order.get("sku")
            order_date = order.get("order_date")
            
            if sku and order_date:
                supplier_price = get_historical_price_batch(
                    sku, 
                    order_date, 
                    sku_to_variant, 
                    variant_to_price, 
                    price_history_cache
                )
                if supplier_price is not None:
                    order["supplier_selling_price"] = supplier_price
                    price_lookups += 1
        
        print(f"💰 Successfully looked up prices for {price_lookups}/{len(orders_needing_price)} new orders")
    else:
        print(f"✅ All orders already have historical prices")

    print(f"📦 Processing {len(order_rows)} orders...")
    for batch in chunked(order_rows):
        upsert_with_retry("orders", batch)
    
    print(f"✅ Upserted {len(order_rows)} orders with historical prices")
    print("=" * 60)

# Main
if __name__ == "__main__":
    sync_orders()
    print("🚀 Sync complete")
