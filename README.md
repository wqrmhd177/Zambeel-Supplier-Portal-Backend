# Zambeel Supplier Portal - Backend

Backend API for syncing orders from Metabase to Supabase.

## 🚀 Deployment

Deployed on Vercel as serverless functions.

### API Endpoints

- `GET /api/sync` - Trigger order synchronization
- Runs automatically every hour via Vercel Cron

## 🔐 Environment Variables

Required environment variables on Vercel:

```
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

## 📦 Local Development

```bash
pip install -r requirements.txt
python main.py
```

## ⚙️ How It Works

1. Fetches orders from Metabase public API
2. Syncs to Supabase orders table
3. Preserves historical prices for existing orders
4. Looks up current prices for new orders
