# UUID vs Google Sub Fix

## Problem
Error: `invalid input syntax for type uuid: "100368505623607269813"`

The backend was receiving the Google sub (a number string like "100368505623607269813") as the `user_id` parameter, but trying to use it directly in Supabase queries that expect a UUID format.

## Root Cause
The API endpoint accepts `user_id` as a query parameter, which the frontend sends as the Google sub. However, the Supabase database uses UUIDs as primary keys, not Google subs.

The flow was:
1. Frontend sends Google sub as `user_id` → `"100368505623607269813"`
2. Backend tries to query `encrypted_tokens` table with this value
3. Supabase expects UUID format → Error!

## Solution
Updated `SupabaseService.get_encrypted_token()` to automatically detect and handle both formats:

1. **Added `get_user_by_google_sub()` method** - Looks up user UUID from Google sub
2. **Updated `get_encrypted_token()` to auto-detect** - If the user_id doesn't contain hyphens (not a UUID), it treats it as a Google sub and looks up the actual UUID first

### Code Changes

**backend/app/services/supabase_service.py:**
```python
async def get_encrypted_token(self, user_id: str, token_type: str):
    # Check if user_id is a UUID or Google sub
    actual_user_id = user_id
    
    # Simple check: UUIDs contain hyphens, Google subs don't
    if '-' not in user_id:
        # This is a Google sub, look up the UUID
        user = await self.get_user_by_google_sub(user_id)
        if not user:
            return None
        actual_user_id = user["id"]
    
    # Now query with the actual UUID
    response = self.client.table("encrypted_tokens")
        .select("encrypted_token")
        .eq("user_id", actual_user_id)
        .eq("token_type", token_type)
        .execute()
    ...
```

## Testing
1. Restart the backend: `cd backend && uv run python run.py`
2. Open a PDF in the app
3. Click the info icon (ⓘ) to open metadata sidebar
4. Metadata should now load successfully

## Expected Behavior
- The backend now accepts Google sub as `user_id` parameter
- Automatically looks up the corresponding UUID in the database
- Fetches the encrypted tokens using the correct UUID
- Metadata extraction proceeds normally

## Why This Works
- **Backward compatible**: Still works if a UUID is passed
- **Automatic detection**: No API changes needed
- **Simple logic**: UUIDs have hyphens, Google subs don't
- **Efficient**: Only does lookup when needed

## Related Files
- `backend/app/services/supabase_service.py` - Fixed token lookup
- `backend/app/routers/metadata.py` - Improved error messages
- `backend/app/services/drive_service.py` - Uses the fixed service

## Notes
- The Google sub is the user's unique identifier from Google OAuth
- The UUID is the database primary key in Supabase
- The `users` table has both: `id` (UUID) and `google_sub` (string)
- The `encrypted_tokens` table references `user_id` (UUID foreign key)
