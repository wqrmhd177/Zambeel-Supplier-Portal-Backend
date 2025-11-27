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

# Sync Orders
def sync_orders():
    """Sync orders from Metabase to Supabase."""
    print("=" * 60)
    print("Orders Sync Script")
    print("=" * 60)
    
    print("Fetching orders from Metabase...")
    orders_data = fetch_json(ORDERS_URL)
    print(f"✅ Fetched {len(orders_data)} orders")
    
    order_rows = []
    skipped = 0

    for row in orders_data:
        order_id = row.get("order_id")
        sku = row.get("sku")
        
        # Skip rows without both order_id and sku (required for composite key)
        if not order_id or not sku:
            skipped += 1
            continue
            
        order_rows.append({
            "order_id": order_id,
            "sku": sku,
            "vendor_id": row.get("vendor_id"),
            "order_date": row.get("order_date"),
            "phone": row.get("phone"),
            "country": row.get("country"),
            "title": row.get("title"),
            "total_payable": row.get("total_payable", 0.0),
            "status": row.get("status"),
        })

    if skipped > 0:
        print(f"⚠️ Skipped {skipped} orders missing order_id or sku")

    print(f"📦 Processing {len(order_rows)} orders...")
    for batch in chunked(order_rows):
        upsert_with_retry("orders", batch)
    
    print(f"✅ Upserted {len(order_rows)} orders")
    print("=" * 60)

# Main
if __name__ == "__main__":
    sync_orders()
    print("🚀 Sync complete")
