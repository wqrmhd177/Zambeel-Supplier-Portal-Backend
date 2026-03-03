"""
Database Migration Script
Migrates data from old Supabase database to new database
"""

import os
from supabase import create_client, Client
from dotenv import load_dotenv
import time
from typing import List, Dict, Any

# Load environment variables
load_dotenv('.env.local')

# ============================================================================
# CONFIGURATION
# ============================================================================

# OLD DATABASE (source)
OLD_SUPABASE_URL = input("Enter OLD Supabase URL: ").strip()
OLD_SUPABASE_KEY = input("Enter OLD Service Role Key: ").strip()

# NEW DATABASE (destination)
NEW_SUPABASE_URL = "https://puoedxxoxyrdlesdghyp.supabase.co"
NEW_SUPABASE_KEY = input("Enter NEW Service Role Key: ").strip()

# Tables to migrate (in order to respect dependencies)
# Note: Only 4 core tables matching your existing structure
# No supplier_purchaser table - relationship stored in users.purchaser_id
TABLES_TO_MIGRATE = [
    'users',
    'products',
    'orders',
    'price_history',
]

# Batch size for migration
BATCH_SIZE = 500

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def create_clients():
    """Create Supabase clients for old and new databases"""
    print("Connecting to databases...")
    old_client = create_client(OLD_SUPABASE_URL, OLD_SUPABASE_KEY)
    new_client = create_client(NEW_SUPABASE_URL, NEW_SUPABASE_KEY)
    print("✅ Connected to both databases")
    return old_client, new_client

def get_table_count(client: Client, table: str) -> int:
    """Get count of records in a table"""
    try:
        response = client.table(table).select('*', count='exact').limit(1).execute()
        return response.count if response.count else 0
    except Exception as e:
        print(f"⚠️ Error getting count for {table}: {e}")
        return 0

def migrate_table(old_client: Client, new_client: Client, table: str) -> Dict[str, Any]:
    """Migrate a single table from old to new database"""
    print(f"\n{'='*60}")
    print(f"Migrating table: {table}")
    print(f"{'='*60}")
    
    stats = {
        'table': table,
        'total_records': 0,
        'migrated': 0,
        'failed': 0,
        'errors': []
    }
    
    try:
        # Get total count
        total_count = get_table_count(old_client, table)
        stats['total_records'] = total_count
        print(f"📊 Total records to migrate: {total_count}")
        
        if total_count == 0:
            print(f"⚠️ No records found in {table}")
            return stats
        
        # Fetch all records in batches
        offset = 0
        while offset < total_count:
            print(f"📥 Fetching records {offset} to {offset + BATCH_SIZE}...")
            
            # Fetch batch from old database
            response = old_client.table(table).select('*').range(offset, offset + BATCH_SIZE - 1).execute()
            
            if not response.data:
                break
            
            batch = response.data
            print(f"✅ Fetched {len(batch)} records")
            
            # Insert batch into new database
            print(f"📤 Inserting {len(batch)} records into new database...")
            
            for record in batch:
                try:
                    # Remove any auto-generated fields that might cause conflicts
                    if 'id' in record and table == 'users':
                        # For users table with SERIAL id, let it auto-generate
                        record_copy = {k: v for k, v in record.items() if k != 'id'}
                    else:
                        record_copy = record.copy()
                    
                    # Insert record
                    new_client.table(table).insert(record_copy).execute()
                    stats['migrated'] += 1
                    
                except Exception as e:
                    stats['failed'] += 1
                    error_msg = f"Failed to insert record: {str(e)[:100]}"
                    stats['errors'].append(error_msg)
                    print(f"❌ {error_msg}")
            
            print(f"✅ Inserted batch. Progress: {stats['migrated']}/{total_count}")
            
            offset += BATCH_SIZE
            time.sleep(0.5)  # Rate limiting
        
        print(f"\n✅ Migration complete for {table}")
        print(f"   - Total: {stats['total_records']}")
        print(f"   - Migrated: {stats['migrated']}")
        print(f"   - Failed: {stats['failed']}")
        
    except Exception as e:
        print(f"❌ Error migrating {table}: {e}")
        stats['errors'].append(str(e))
    
    return stats

def verify_migration(old_client: Client, new_client: Client, table: str) -> bool:
    """Verify that migration was successful"""
    try:
        old_count = get_table_count(old_client, table)
        new_count = get_table_count(new_client, table)
        
        if old_count == new_count:
            print(f"✅ Verification passed for {table}: {new_count} records")
            return True
        else:
            print(f"⚠️ Verification warning for {table}: Old={old_count}, New={new_count}")
            return False
    except Exception as e:
        print(f"❌ Verification error for {table}: {e}")
        return False

# ============================================================================
# MAIN MIGRATION FUNCTION
# ============================================================================

def main():
    """Main migration function"""
    print("\n" + "="*60)
    print("DATABASE MIGRATION TOOL")
    print("="*60)
    print(f"\nSource: {OLD_SUPABASE_URL}")
    print(f"Destination: {NEW_SUPABASE_URL}")
    print(f"\nTables to migrate: {', '.join(TABLES_TO_MIGRATE)}")
    
    # Confirm before proceeding
    confirm = input("\n⚠️ This will copy data to the new database. Continue? (yes/no): ").strip().lower()
    if confirm != 'yes':
        print("❌ Migration cancelled")
        return
    
    # Create clients
    try:
        old_client, new_client = create_clients()
    except Exception as e:
        print(f"❌ Failed to connect to databases: {e}")
        return
    
    # Migration statistics
    all_stats = []
    start_time = time.time()
    
    # Migrate each table
    for table in TABLES_TO_MIGRATE:
        stats = migrate_table(old_client, new_client, table)
        all_stats.append(stats)
        
        # Verify migration
        verify_migration(old_client, new_client, table)
        
        # Pause between tables
        time.sleep(1)
    
    # Calculate total time
    end_time = time.time()
    duration = end_time - start_time
    
    # Print summary
    print("\n" + "="*60)
    print("MIGRATION SUMMARY")
    print("="*60)
    
    total_migrated = 0
    total_failed = 0
    
    for stats in all_stats:
        print(f"\n{stats['table']}:")
        print(f"  Total: {stats['total_records']}")
        print(f"  Migrated: {stats['migrated']}")
        print(f"  Failed: {stats['failed']}")
        
        if stats['errors']:
            print(f"  Errors: {len(stats['errors'])}")
            for error in stats['errors'][:3]:  # Show first 3 errors
                print(f"    - {error}")
        
        total_migrated += stats['migrated']
        total_failed += stats['failed']
    
    print(f"\n{'='*60}")
    print(f"TOTAL MIGRATED: {total_migrated}")
    print(f"TOTAL FAILED: {total_failed}")
    print(f"DURATION: {duration:.2f} seconds")
    print(f"{'='*60}")
    
    if total_failed == 0:
        print("\n✅ Migration completed successfully!")
    else:
        print(f"\n⚠️ Migration completed with {total_failed} failures")
        print("Please review the errors above and manually fix any issues")
    
    # Final verification
    print("\n" + "="*60)
    print("FINAL VERIFICATION")
    print("="*60)
    
    all_verified = True
    for table in TABLES_TO_MIGRATE:
        verified = verify_migration(old_client, new_client, table)
        if not verified:
            all_verified = False
    
    if all_verified:
        print("\n✅ All tables verified successfully!")
    else:
        print("\n⚠️ Some tables have count mismatches. Please review.")

# ============================================================================
# RUN MIGRATION
# ============================================================================

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n❌ Migration cancelled by user")
    except Exception as e:
        print(f"\n\n❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
