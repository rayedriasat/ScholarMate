# Token Refresh Flow Diagram

## Complete Authentication & Token Lifecycle

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER SIGNS IN                           │
│                              ↓                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 1. Google OAuth Flow                                     │  │
│  │    - User clicks "Sign in with Google"                   │  │
│  │    - Google consent screen                               │  │
│  │    - Returns: access_token, id_token                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              ↓                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 2. Store Tokens Locally (SharedPreferences)             │  │
│  │    - access_token                                        │  │
│  │    - id_token                                            │  │
│  │    - token_expiry: now + 50 minutes                      │  │
│  │    - last_auth_time: now                                 │  │
│  │    - session_expiry: now + 30 days                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              ↓                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 3. Store Tokens in Backend (Encrypted)                  │  │
│  │    - POST /api/auth/store-tokens                         │  │
│  │    - Supabase: users + encrypted_tokens tables           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                              ↓                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 4. Start Periodic Refresh Timer                          │  │
│  │    - Timer fires every 45 minutes                        │  │
│  │    - Checks if token needs refresh                       │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    NORMAL OPERATION (< 50 min)                  │
│                              ↓                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ User makes API call (e.g., open file)                   │  │
│  │    ↓                                                     │  │
│  │ getAccessToken() called                                  │  │
│  │    ↓                                                     │  │
│  │ Check: areTokensValid()?                                 │  │
│  │    ↓ YES                                                 │  │
│  │ Return cached token ✓                                    │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                  TOKEN EXPIRY (after 50 min)                    │
│                              ↓                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Timer fires OR API call made                             │  │
│  │    ↓                                                     │  │
│  │ Check: needsTokenRefresh()?                              │  │
│  │    ↓ YES                                                 │  │
│  │ Call refreshToken()                                      │  │
│  │    ↓                                                     │  │
│  │ ┌────────────────────────────────────────────────────┐  │  │
│  │ │ Silent Token Refresh                               │  │  │
│  │ │ 1. clearAuthorizationToken() - invalidate old      │  │  │
│  │ │ 2. authorizationForScopes() - get new token        │  │  │
│  │ │ 3. Update local storage (new expiry)               │  │  │
│  │ │ 4. Update backend (encrypted)                      │  │  │
│  │ │ 5. Update _currentUser                             │  │  │
│  │ └────────────────────────────────────────────────────┘  │  │
│  │    ↓                                                     │  │
│  │ Return new token ✓                                       │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    APP RESTART (< 30 days)                      │
│                              ↓                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 1. App Initialization                                    │  │
│  │    ↓                                                     │  │
│  │ 2. Restore user from SharedPreferences                   │  │
│  │    ↓                                                     │  │
│  │ 3. Check: isSessionValid()?                              │  │
│  │    ↓ YES (< 30 days)                                     │  │
│  │ 4. Check: areTokensValid()?                              │  │
│  │    ├─ YES → Use cached tokens ✓                          │  │
│  │    └─ NO → Silent refresh ↓                              │  │
│  │         ├─ Success → User signed in ✓                    │  │
│  │         └─ Fail → Retry on next API call                 │  │
│  │    ↓                                                     │  │
│  │ 5. Start refresh timer                                   │  │
│  │    ↓                                                     │  │
│  │ 6. Navigate to HomeScreen ✓                              │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                  SESSION EXPIRY (after 30 days)                 │
│                              ↓                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 1. App Initialization                                    │  │
│  │    ↓                                                     │  │
│  │ 2. Restore user from SharedPreferences                   │  │
│  │    ↓                                                     │  │
│  │ 3. Check: isSessionValid()?                              │  │
│  │    ↓ NO (> 30 days)                                      │  │
│  │ 4. Clear user data                                       │  │
│  │    ↓                                                     │  │
│  │ 5. Navigate to LoginScreen                               │  │
│  │    ↓                                                     │  │
│  │ 6. User must sign in again                               │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         USER SIGNS OUT                          │
│                              ↓                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ 1. Stop refresh timer                                    │  │
│  │    ↓                                                     │  │
│  │ 2. Delete tokens from backend                            │  │
│  │    ↓                                                     │  │
│  │ 3. Clear SharedPreferences                               │  │
│  │    ↓                                                     │  │
│  │ 4. Clear _currentUser                                    │  │
│  │    ↓                                                     │  │
│  │ 5. Navigate to LoginScreen                               │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Token States

```
┌─────────────────────────────────────────────────────────────┐
│                      TOKEN STATES                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  VALID (< 50 min)                                           │
│  ├─ Use cached token                                        │
│  └─ No refresh needed                                       │
│                                                             │
│  EXPIRED (> 50 min, < 30 days)                              │
│  ├─ Silent refresh                                          │
│  ├─ Update storage                                          │
│  └─ Continue using app                                      │
│                                                             │
│  SESSION EXPIRED (> 30 days)                                │
│  ├─ Clear all data                                          │
│  ├─ Require re-authentication                               │
│  └─ User must sign in again                                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Refresh Timer Behavior

```
Time:     0 min    45 min    90 min    135 min   180 min
          │        │         │         │         │
Sign In   ●────────┼─────────┼─────────┼─────────┼────→
          │        │         │         │         │
Token     │        │         │         │         │
Expiry:   │        ↓         ↓         ↓         ↓
          │     [Check]   [Check]   [Check]   [Check]
          │        │         │         │         │
          │        ├─ Expired? → Refresh
          │        └─ Valid? → Skip
          │
          └─ Timer started (fires every 45 min)
```

## Storage Structure

```
SharedPreferences
├─ flutter.current_user
│  └─ JSON: {id, email, displayName, photoUrl, accessToken, idToken}
│
├─ flutter.access_token
│  └─ String: "ya29.a0AfH6SMB..."
│
├─ flutter.id_token
│  └─ String: "eyJhbGciOiJSUzI1NiIs..."
│
├─ flutter.token_expiry
│  └─ Int: 1699876543210 (timestamp: now + 50 min)
│
└─ flutter.last_auth_time
   └─ Int: 1699873543210 (timestamp: sign-in time)
```

## Decision Tree

```
                    App Starts
                        │
                        ↓
              ┌─────────────────┐
              │ User in storage?│
              └─────────────────┘
                   │         │
              YES  │         │  NO
                   ↓         ↓
         ┌──────────────┐   LoginScreen
         │Session valid?│
         └──────────────┘
              │         │
         YES  │         │  NO
              ↓         ↓
      ┌──────────────┐  Clear data
      │Tokens valid? │  → LoginScreen
      └──────────────┘
           │         │
      YES  │         │  NO
           ↓         ↓
      HomeScreen  Silent refresh
                      │
                      ├─ Success → HomeScreen
                      └─ Fail → Retry later
```

## Error Handling

```
Token Refresh Failed
        │
        ↓
┌───────────────────┐
│ Network offline?  │
└───────────────────┘
        │
   YES  │  NO
        ↓  ↓
    Retry  ┌─────────────────────┐
    later  │ OAuth revoked?      │
           └─────────────────────┘
                    │
               YES  │  NO
                    ↓  ↓
            Re-auth  Log error
            required & retry
```

## Key Timings

| Event | Timing | Action |
|-------|--------|--------|
| Token expiry | 50 minutes | Auto-refresh |
| Timer check | Every 45 minutes | Check & refresh if needed |
| Session expiry | 30 days | Require re-authentication |
| Refresh margin | 10 minutes | Refresh before actual expiry |

## Summary

- **Token lifetime**: 50 minutes (Google's 1 hour - 10 min margin)
- **Check frequency**: Every 45 minutes (before expiry)
- **Session lifetime**: 30 days (user stays logged in)
- **Refresh type**: Silent (no user interaction)
- **Storage**: Local (SharedPreferences) + Backend (Supabase)
- **Fallback**: Retry on next API call if refresh fails
