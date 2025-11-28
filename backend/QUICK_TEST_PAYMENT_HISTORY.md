# Quick Test: Payment History Endpoint

## Prerequisites

1. **Database Migration Applied**
   ```bash
   # Check if migration is applied
   psql $DATABASE_URL -c "SELECT column_name FROM information_schema.columns WHERE table_name='transactions';"
   ```
   
   If not applied, run:
   ```bash
   psql $DATABASE_URL -f backend/supabase_migrations/006_subscription_system.sql
   ```

2. **Backend Running**
   ```bash
   cd backend
   uv run python run.py
   ```

## Quick Manual Test

### 1. Create Test User (if needed)
```bash
# Use an existing user's google_sub from your database
# Or create one via the auth flow
```

### 2. Create Test Transactions
```bash
# Initialize a payment first
curl -X POST "http://localhost:8000/api/payments/initialize" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "YOUR_GOOGLE_SUB",
    "payment_method": "bkash",
    "amount": 999.00,
    "currency": "BDT"
  }'

# Note the transaction_id from response

# Verify the payment
curl -X POST "http://localhost:8000/api/payments/verify" \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TRANSACTION_ID_FROM_ABOVE",
    "payment_credentials": {
      "mobile_number": "01712345678",
      "pin": "12345"
    }
  }'
```

### 3. Get Payment History
```bash
# Get all transactions
curl "http://localhost:8000/api/payments/history?user_id=YOUR_GOOGLE_SUB"

# Get with pagination
curl "http://localhost:8000/api/payments/history?user_id=YOUR_GOOGLE_SUB&limit=10&offset=0"
```

### Expected Response
```json
{
  "transactions": [
    {
      "transaction_id": "TXN_XXXXXXXXXXXX",
      "payment_method": "bkash",
      "amount": 999.0,
      "currency": "BDT",
      "status": "success",
      "created_at": "2025-11-28T14:30:00.000000Z",
      "verified_at": "2025-11-28T14:30:05.000000Z"
    }
  ],
  "total_count": 1
}
```

## Run Automated Tests

```bash
cd backend
uv run pytest test_payment_history_api.py -v
```

## Test Swagger UI

1. Open browser: http://localhost:8000/docs
2. Find "GET /api/payments/history" endpoint
3. Click "Try it out"
4. Enter user_id parameter
5. Click "Execute"
6. View response

## Common Issues

### Issue: "Could not find the 'subscription_status' column"
**Solution**: Apply the database migration (see Prerequisites)

### Issue: "User not found"
**Solution**: Use a valid google_sub from an existing user in your database

### Issue: Empty transactions array
**Solution**: Create some test transactions first (see step 2 above)

## Verification Checklist

- [ ] Endpoint returns 200 for valid user
- [ ] Response includes transactions array and total_count
- [ ] Transactions are ordered by created_at descending (newest first)
- [ ] Pagination works with limit and offset
- [ ] Returns 404 for non-existent user
- [ ] Returns 400 for invalid limit (0, negative, >100)
- [ ] Returns 400 for negative offset
- [ ] Each transaction has all required fields
- [ ] verified_at is null for pending transactions
- [ ] verified_at is present for success/failed transactions

## Next Steps

Once verified:
1. ✅ Mark task 4.5 as complete
2. Move to Task 5: Checkpoint - Ensure backend tests pass
3. Begin frontend implementation (Task 6+)
