import os
import requests
from supabase import create_client, Client
import time
from http.server import BaseHTTPRequestHandler
import json

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
            return supabase.table(table).upsert(data, on_conflict="order_id,sku").execute()
        except (TypeError, AttributeError):
            return supabase.table(table).upsert(data).execute()
        except Exception as e:
            if attempt < max_retries - 1:
                print(f"⚠️ Attempt {attempt + 1} failed, retrying...")
                time.sleep(5)
            else:
                raise

def build_price_lookup_maps(unique_skus):
    """Build lookup maps for SKU->variant_id and variant_id->current_price in batch."""
    try:
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
                    if sku not in sku_to_variant:
                        sku_to_variant[sku] = variant_id
                        variant_to_price[variant_id] = price
        
        return sku_to_variant, variant_to_price
    except Exception as e:
        print(f"⚠️ Error building price lookup maps: {e}")
        return {}, {}

def get_historical_price_batch(sku: str, order_date: str, sku_to_variant: dict, variant_to_price: dict, price_history_cache: dict):
    """Get historical price using pre-loaded lookup maps."""
    variant_id = sku_to_variant.get(sku)
    if not variant_id:
        return None
    
    current_price = variant_to_price.get(variant_id)
    
    if variant_id in price_history_cache:
        history_entries = price_history_cache[variant_id]
        for entry in history_entries:
            if entry['created_at'] <= order_date and entry['status'] == 'approved':
                return entry['updated_price']
    
    return current_price

def sync_orders():
    """Sync orders from Metabase to Supabase with historical prices."""
    print("=" * 60)
    print("Orders Sync Script with Historical Pricing")
    print("=" * 60)
    
    print("Fetching orders from Metabase...")
    try:
        response = fetch_json(ORDERS_URL)
        
        # Handle different response formats from Metabase
        if isinstance(response, dict):
            # If response is a dict, try to extract the data array
            # Common keys: 'data', 'rows', 'results'
            if 'data' in response:
                orders_data = response['data']
            elif 'rows' in response:
                orders_data = response['rows']
            elif 'results' in response:
                orders_data = response['results']
            else:
                # If it's a dict but doesn't have expected keys, treat it as a single row
                orders_data = [response]
        elif isinstance(response, list):
            orders_data = response
        else:
            raise ValueError(f"Unexpected response type from Metabase: {type(response)}")
        
        if len(orders_data) == 0:
            return {
                "success": True,
                "message": "No orders found from Metabase",
                "total_orders": 0
            }
        
        # Check if first item is a dict
        if not isinstance(orders_data[0], dict):
            raise ValueError(f"Expected dict in orders list, got {type(orders_data[0])}. First item: {orders_data[0]}")
        
        print(f"✅ Fetched {len(orders_data)} orders")
    except Exception as e:
        error_msg = f"Error fetching orders from Metabase: {str(e)}"
        print(f"❌ {error_msg}")
        raise Exception(error_msg)
    
    print("Fetching existing orders from Supabase...")
    existing_orders = {}
    try:
        offset = 0
        batch_size = 1000
        
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
            
            if len(response.data) < batch_size:
                break
            
            offset += batch_size
        
        print(f"✅ Found {len(existing_orders)} existing orders in Supabase")
    except Exception as e:
        print(f"⚠️ Error fetching existing orders: {e}")
    
    order_rows = []
    skipped = 0
    unique_skus = set()
    orders_needing_price = []

    for row in orders_data:
        order_id = row.get("order_id")
        sku = row.get("sku")
        order_date = row.get("order_date")
        
        if not order_id or not sku:
            skipped += 1
            continue
        
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
            "supplier_selling_price": existing_price,
        }
        
        if existing_price is None and sku:
            unique_skus.add(sku)
            orders_needing_price.append(order_row)
        
        order_rows.append(order_row)

    if skipped > 0:
        print(f"⚠️ Skipped {skipped} orders missing order_id or sku")
    
    orders_with_prices = len(order_rows) - len(orders_needing_price)
    print(f"📊 {orders_with_prices} orders have prices, {len(orders_needing_price)} need lookup")
    
    if orders_needing_price:
        print(f"🔍 Building price lookup maps for {len(unique_skus)} unique SKUs...")
        sku_to_variant, variant_to_price = build_price_lookup_maps(list(unique_skus))
        print(f"✅ Found products for {len(sku_to_variant)} SKUs")
        
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
                    for entry in history_response.data:
                        variant_id = entry['variant_id']
                        if variant_id not in price_history_cache:
                            price_history_cache[variant_id] = []
                        price_history_cache[variant_id].append(entry)
                    
                    print(f"✅ Loaded {len(history_response.data)} price history entries")
            except Exception as e:
                print(f"⚠️ Error fetching price history: {e}")
        
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
        
        print(f"💰 Successfully looked up prices for {price_lookups}/{len(orders_needing_price)} orders")
    else:
        print(f"✅ All orders already have historical prices")

    print(f"📦 Processing {len(order_rows)} orders...")
    for batch in chunked(order_rows):
        upsert_with_retry("orders", batch)
    
    print(f"✅ Upserted {len(order_rows)} orders with historical prices")
    print("=" * 60)
    
    return {
        "success": True,
        "total_orders": len(order_rows),
        "orders_with_prices": orders_with_prices,
        "new_price_lookups": len(orders_needing_price)
    }

# Vercel serverless function handler
class handler(BaseHTTPRequestHandler):
    def do_GET(self):
        try:
            result = sync_orders()
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(result, indent=2).encode())
        except Exception as e:
            import traceback
            error_details = {
                "error": str(e),
                "type": type(e).__name__,
                "traceback": traceback.format_exc()
            }
            self.send_response(500)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(error_details, indent=2).encode())
    
    def do_POST(self):
        self.do_GET()
