# Authentication Flow Test

## Issue Identified

The "User not found" error occurs because users are not being automatically created in the Supabase database when they sign in with Google. The frontend `AuthService` was only storing user data locally but not calling the backend `/store-tokens` endpoint.

## Fix Applied

Updated `frontend/lib/services/auth_service.dart` to:

1. Import `ApiService`
2. Call `_storeUserInBackend()` after successful authentication
3. Store user and tokens in the backend database via `/api/auth/store-tokens`

## Testing Steps

### 1. Backend Health Check
```bash
curl http://localhost:8000/api/health
```
Expected: `{"status": "healthy"}`

### 2. Manual User Creation (for testing)
```bash
curl -X POST http://localhost:8000/api/auth/store-tokens \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "112242426759250477538",
    "email": "test@example.com",
    "name": "Test User",
    "access_token": "test_token"
  }'
```

### 3. Verify User Creation
Check in Supabase dashboard or via SQL:
```sql
SELECT google_sub, email, name FROM users WHERE google_sub = '112242426759250477538';
```

### 4. Test Sharing Endpoint
```bash
curl http://localhost:8000/api/sharing/shared-with-me/112242426759250477538
```
Expected: `{"success": true, "shared_files": []}`

## Frontend Changes

The updated `AuthService` now:
- ✅ Calls backend after Google sign-in
- ✅ Creates user record in database
- ✅ Stores encrypted tokens
- ✅ Handles errors gracefully (doesn't break local auth)

## Database Status

Current users in database:
- `111828646872592591995` - coderay231@gmail.com (existing)
- `112242426759250477538` - Will be created on next sign-in

## Next Steps

1. ✅ User authentication flow fixed
2. 🔄 Test frontend sign-in creates backend user
3. 🔄 Test sharing functionality works
4. 🔄 Verify all API endpoints work with new schema

The authentication flow should now work end-to-end, creating users in the database automatically when they sign in through the frontend.