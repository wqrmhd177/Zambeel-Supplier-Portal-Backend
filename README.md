# Supplier Portal - Backend

Python backend scripts for syncing orders data from Metabase to Supabase.

## Features

- Fetches orders data from Metabase public API
- Syncs orders to Supabase database
- Handles upsert operations (insert new, update existing)
- Retry logic for failed operations

## Prerequisites

- Python 3.8 or higher
- pip (Python package manager)

## Installation

1. Navigate to the backend directory:
```bash
cd backend
```

2. Create a virtual environment (recommended):
```bash
python -m venv venv
```

3. Activate the virtual environment:
   - On Windows: `venv\Scripts\activate`
   - On macOS/Linux: `source venv/bin/activate`

4. Install dependencies:
```bash
pip install -r requirements.txt
```

## Configuration

1. Copy the environment template:
```bash
copy .env.example .env.local
```

2. Edit `.env.local` and add your Supabase credentials:
```
SUPABASE_URL=your_supabase_project_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

## Database Setup

Before running the sync script, ensure the orders table exists in your Supabase database. Run the SQL script:

```bash
# Execute create_orders_table.sql in your Supabase SQL editor
```

Or use the Supabase dashboard to run the SQL from `create_orders_table.sql`.

## Usage

Run the orders sync script:

```bash
python main.py
```

This will:
1. Fetch orders from Metabase
2. Transform the data
3. Upsert orders to Supabase (insert new, update existing based on order_id)

## Script Details

- **Metabase URL**: Configured in `main.py` (ORDERS_URL)
- **Sync Frequency**: Run manually or set up as a scheduled task/cron job
- **Data Columns**: order_id, vendor_id, order_date, phone, country, title, sku, total_payable, status

## Environment Variables

- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key for backend operations
- `SUPABASE_KEY`: Optional fallback key

## Notes

- The script uses upsert operations, so running it multiple times is safe
- Orders are identified by `order_id` (unique constraint)
- Failed operations will be retried up to 3 times

