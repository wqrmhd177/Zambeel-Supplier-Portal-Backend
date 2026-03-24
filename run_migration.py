#!/usr/bin/env python3
"""
Run SQL migration script against Supabase database
"""
import os
import sys
from pathlib import Path
from supabase import create_client, Client

def run_migration(sql_file: str):
    """Execute a SQL migration file"""
    # Load environment variables
    env_file = Path(__file__).parent / '.env.local.new'
    if env_file.exists():
        with open(env_file) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key.strip()] = value.strip()
    
    supabase_url = os.getenv('SUPABASE_URL')
    supabase_key = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
    
    if not supabase_url or not supabase_key:
        print("❌ Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set")
        sys.exit(1)
    
    # Read SQL file
    sql_path = Path(__file__).parent / sql_file
    if not sql_path.exists():
        print(f"❌ Error: SQL file not found: {sql_path}")
        sys.exit(1)
    
    with open(sql_path, 'r', encoding='utf-8') as f:
        sql_content = f.read()
    
    print(f"📝 Running migration: {sql_file}")
    print(f"🔗 Database: {supabase_url}")
    print()
    
    # Create Supabase client
    supabase: Client = create_client(supabase_url, supabase_key)
    
    try:
        # Execute SQL via RPC call to a custom function, or use REST API
        # Since Supabase Python client doesn't have direct SQL execution,
        # we'll use the PostgREST API directly
        import requests
        
        # Use the Supabase REST API to execute SQL
        headers = {
            'apikey': supabase_key,
            'Authorization': f'Bearer {supabase_key}',
            'Content-Type': 'application/json',
            'Prefer': 'return=representation'
        }
        
        # Note: Direct SQL execution via REST API is not supported
        # We need to use the Supabase SQL editor or create an RPC function
        print("⚠️  Note: This script cannot execute raw SQL directly via the Python client.")
        print("📋 Please run the following SQL in your Supabase SQL Editor:")
        print()
        print("=" * 80)
        print(sql_content)
        print("=" * 80)
        print()
        print("✅ After running the SQL, the following will be created:")
        print("   - products.options (jsonb) - stores variant option definitions")
        print("   - products.has_variants (boolean) - quick flag for products with variants")
        print("   - product_variants table - stores individual variant rows")
        print("   - Indexes on product_id and (product_id, active)")
        print("   - RLS policies for authenticated users")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    if len(sys.argv) > 1:
        sql_file = sys.argv[1]
    else:
        sql_file = 'create_product_variants_table.sql'
    
    run_migration(sql_file)
