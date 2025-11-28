# Quick Test: Subscription Status Endpoint

## Endpoint Implemented

✅ **GET /api/payments/subscription-status**

## What It Does

Retrieves the current subscription status for a user, including:
- Plan type (free or premium)
- Activation timestamp (when premium was activated)
- Expiry timestamp (when premium expires)
- Active status (whether subscription is currently valid)

## How to Test

### Prerequisites

⚠️ **Database Migration Required**: Before testing, apply the subscription migration:

```bash
# Option 1: Via Supabase Dashboard (Recommended)
# 1. Go to Supabase SQL Editor
# 2. Copy contents of backend/supabase_migrations/006_subscription_system.sql
# 3. Click "Run"

# Option 2: Via Python (if DATABASE_URL configured)
cd backend
uv run python apply_subscription_migration.py
```

### Test with curl

```bash
# Test with existing user (replace with actual google_sub)
curl "http://localhost:8000/api/payments/subscription-status?user_id=YOUR_GOOGLE_SUB"

# Expected response for free user:
{
    "plan": "free",
    "activated_at": null,
    "expires_at": null,
    "is_active": false
}

# Expected response for premium user:
{
    "plan": "premium",
    "activated_at": "2024-01-15T10:30:00Z",
    "expires_at": "2025-01-15T10:30:00Z",
    "is_active": true
}
```

### Test with Python

```python
import requests

# Replace with actual google_sub
user_id = "your_google_sub_here"

response = requests.get(
    "http://localhost:8000/api/payments/subscription-status",
    params={"user_id": user_id}
)

print(response.json())
```

### Run Automated Tests

```bash
cd backend
uv run pytest test_subscription_status_api.py -v
```

## API Documentation

Once the backend is running, view the interactive API docs:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

Look for the `/api/payments/subscription-status` endpoint in the "payments" section.

## Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `plan` | string | "free" or "premium" |
| `activated_at` | datetime\|null | When premium was activated (null for free users) |
| `expires_at` | datetime\|null | When premium expires (null for free users) |
| `is_active` | boolean | Whether subscription is currently active |

## Error Responses

### User Not Found (404)
```json
{
    "error": {
        "message": "User not found: nonexistent_user",
        "status_code": 404,
        "request_id": "..."
    }
}
```

### Missing user_id (422)
```json
{
    "detail": [
        {
            "type": "missing",
            "loc": ["query", "user_id"],
            "msg": "Field required"
        }
    ]
}
```

## Integration with Frontend

The frontend can use this endpoint to:

1. **Check subscription status on app load**
   ```dart
   final status = await subscriptionService.loadSubscriptionStatus();
   ```

2. **Show/hide premium features**
   ```dart
   if (status.isPremium && status.isActive) {
     // Show premium features
   }
   ```

3. **Display subscription info in Settings**
   ```dart
   Text('Plan: ${status.plan}')
   Text('Expires: ${status.expiresAt}')
   ```

## Next Steps

After testing this endpoint:

1. ✅ Task 4.4 complete
2. ⏭️ Implement Task 4.5: GET /api/payments/history endpoint
3. ⏭️ Implement frontend SubscriptionService
4. ⏭️ Wire up Settings screen to display subscription status

## Troubleshooting

### "Could not find the 'subscription_status' column"

**Solution**: Apply the database migration first (see Prerequisites above)

### "User not found"

**Solution**: Make sure you're using a valid google_sub from an existing user in your database

### Connection errors

**Solution**: Ensure the backend is running (`uv run python run.py`) and Supabase credentials are configured in `.env`
