# Long-Term Authentication Solution - Stay Logged In for Days/Weeks

## Your Requirements

✅ **User stays logged in** even after 4+ hours of inactivity  
✅ **Backend has uninterrupted access** to Drive API  
✅ **No re-authentication** needed unless explicitly signing out  
✅ **Refresh tokens used properly** for long-term access

## Current Problem

### Frontend (google_sign_in_all_platforms)
- ✅ Has refresh token internally
- ✅ Can refresh access tokens automatically
- ❌ Doesn't expose refresh token to backend
- ❌ Backend stores "CLIENT_MANAGED" placeholder

### Backend
- ✅ Can refresh tokens if it has the refresh token
- ❌ Currently stores "CLIENT_MANAGED" instead of real refresh token
- ❌ Can't refresh tokens independently when user is offline

## The Solution: Server Auth Code Flow

To give your backend long-term access, you need to use **Server Auth Code** during sign-in. This gives the backend a real refresh token.

### How Google OAuth Works

```
┌─────────────────────────────────────────────────────┐
│  Standard OAuth Flow (Current - Limited)            │
├─────────────────────────────────────────────────────┤
│                                                      │
│  User Signs In                                       │
│    ↓                                                 │
│  Frontend gets: Access Token + Refresh Token        │
│    ↓                                                 │
│  Frontend sends to backend: Access Token only       │
│    ↓                                                 │
│  Backend: "CLIENT_MANAGED" (no real refresh token)  │
│    ↓                                                 │
│  ❌ Backend can't refresh independently             │
│                                                      │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  Server Auth Code Flow (Solution - Full Access)     │
├─────────────────────────────────────────────────────┤
│                                                      │
│  User Signs In                                       │
│    ↓                                                 │
│  Frontend gets: Access Token + Server Auth Code     │
│    ↓                                                 │
│  Frontend sends: Server Auth Code to backend        │
│    ↓                                                 │
│  Backend exchanges code for: Refresh Token          │
│    ↓                                                 │
│  ✅ Backend has real refresh token                  │
│  ✅ Can refresh tokens anytime (even offline)       │
│  ✅ Works for days/weeks/months                     │
│                                                      │
└─────────────────────────────────────────────────────┘
```

## Implementation

### Step 1: Update Frontend to Get Server Auth Code

`frontend/lib/services/auth_service.dart`:

```dart
/// Sign in with Google and get server auth code for backend
Future<User?> signInWithGoogle() async {
  if (!_isInitialized) {
    debugPrint('AuthService not initialized');
    return null;
  }

  _setLoading(true);
  try {
    debugPrint('Starting Google sign-in with server auth code...');

    // Clear any existing user data first
    if (_currentUser != null) {
      debugPrint('Clearing existing user data before new sign-in');
      await _clearUserData();
    }

    // Perform sign-in (will try lightweight first, then online if needed)
    final credentials = await _googleSignIn!.signIn();

    if (credentials == null) {
      throw Exception('Sign-in was cancelled or failed');
    }

    // Create user from credentials
    final user = await _createUserFromCredentials(credentials);

    _currentUser = user;

    // Store user data locally
    await StorageService.storeUser(user);

    // Get server auth code for backend
    final serverAuthCode = credentials.serverAuthCode;
    
    if (serverAuthCode != null && serverAuthCode.isNotEmpty) {
      debugPrint('Got server auth code, sending to backend for token exchange');
      // Store tokens AND server auth code in backend
      await _storeUserInBackendWithAuthCode(user, serverAuthCode);
    } else {
      debugPrint('WARNING: No server auth code available - backend will have limited access');
      // Fallback to old method (stores CLIENT_MANAGED)
      await _storeUserInBackend(user);
    }

    _authStateController.add(user);
    notifyListeners();

    debugPrint('Sign-in completed successfully for user: ${user.email}');
    return user;
  } catch (e) {
    debugPrint('Sign-in failed: $e');
    rethrow;
  } finally {
    _setLoading(false);
  }
}

/// Store user and server auth code in backend for token exchange
Future<void> _storeUserInBackendWithAuthCode(User user, String serverAuthCode) async {
  try {
    // Skip if no access token
    if (user.accessToken == null || user.accessToken!.isEmpty) {
      debugPrint('No access token available, skipping backend storage');
      return;
    }

    await ApiService().storeTokensWithAuthCode(
      userId: user.id,
      email: user.email,
      name: user.displayName,
      pictureUrl: user.photoUrl,
      accessToken: user.accessToken!,
      idToken: user.idToken,
      serverAuthCode: serverAuthCode, // Backend will exchange this for refresh token
    );
    
    debugPrint('Successfully stored user and server auth code in backend: ${user.email}');
  } catch (e) {
    debugPrint('Failed to store user in backend: $e');
    // Don't throw - this shouldn't prevent local authentication
  }
}
```

### Step 2: Update API Service

`frontend/lib/services/api_service.dart`:

Add this method:

```dart
/// Store tokens with server auth code (backend exchanges for refresh token)
Future<void> storeTokensWithAuthCode({
  required String userId,
  required String email,
  String? name,
  String? pictureUrl,
  required String accessToken,
  String? idToken,
  required String serverAuthCode,
}) async {
  final url = Uri.parse('${_baseUrl}/auth/store-tokens-with-auth-code');
  
  debugPrint('Storing tokens with auth code for user: $email');
  
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'user_id': userId,
      'email': email,
      'name': name,
      'picture_url': pictureUrl,
      'access_token': accessToken,
      'id_token': idToken,
      'server_auth_code': serverAuthCode,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to store tokens: ${response.body}');
  }
  
  debugPrint('Tokens stored successfully with auth code');
}
```

### Step 3: Update Backend to Exchange Server Auth Code

`backend/app/routers/auth.py`:

```python
from pydantic import BaseModel

class StoreTokensWithAuthCodeRequest(BaseModel):
    user_id: str  # Google sub
    email: str
    name: Optional[str] = None
    picture_url: Optional[str] = None
    access_token: str
    id_token: Optional[str] = None
    server_auth_code: str  # Backend will exchange this for refresh token

@router.post("/store-tokens-with-auth-code", response_model=StoreTokensResponse)
async def store_tokens_with_auth_code(request: StoreTokensWithAuthCodeRequest):
    """
    Store tokens and exchange server auth code for refresh token.
    This gives the backend long-term access to user's Drive.
    """
    try:
        encryption_service = get_encryption_service()
        supabase_service = get_supabase_service()
        
        # Get or create user
        user = await supabase_service.get_or_create_user(
            google_sub=request.user_id,
            email=request.email,
            name=request.name,
            picture_url=request.picture_url
        )
        
        db_user_id = user["id"]
        
        # Exchange server auth code for refresh token
        logger.info(f"Exchanging server auth code for refresh token for user {db_user_id}")
        
        token_url = "https://oauth2.googleapis.com/token"
        
        # Get OAuth credentials from environment
        client_id = os.getenv("GOOGLE_CLIENT_ID")
        client_secret = os.getenv("GOOGLE_CLIENT_SECRET")
        
        data = {
            "code": request.server_auth_code,
            "client_id": client_id,
            "client_secret": client_secret,
            "redirect_uri": "http://localhost:3000",  # Must match Google Console
            "grant_type": "authorization_code"
        }
        
        response = requests.post(token_url, data=data)
        response.raise_for_status()
        
        token_data = response.json()
        backend_access_token = token_data.get("access_token")
        backend_refresh_token = token_data.get("refresh_token")
        
        if not backend_refresh_token:
            logger.warning(f"No refresh token in auth code exchange response for user {db_user_id}")
            logger.warning("This might happen if user already granted access before")
            # Fall back to storing the access token from frontend
            backend_access_token = request.access_token
            backend_refresh_token = None
        else:
            logger.info(f"Successfully obtained refresh token for user {db_user_id}")
        
        # Store access token (use backend's if we got one, otherwise use frontend's)
        encrypted_access_token = encryption_service.encrypt(backend_access_token)
        await supabase_service.store_encrypted_token(
            user_id=db_user_id,
            token_type="access_token",
            encrypted_token=encrypted_access_token
        )
        
        # Store refresh token (real token or CLIENT_MANAGED)
        if backend_refresh_token:
            encrypted_refresh_token = encryption_service.encrypt(backend_refresh_token)
            await supabase_service.store_encrypted_token(
                user_id=db_user_id,
                token_type="refresh_token",
                encrypted_token=encrypted_refresh_token
            )
            logger.info(f"Stored real refresh token for user {db_user_id} - backend has long-term access")
        else:
            # No refresh token - store placeholder
            await supabase_service.store_encrypted_token(
                user_id=db_user_id,
                token_type="refresh_token",
                encrypted_token=encryption_service.encrypt("CLIENT_MANAGED")
            )
            logger.warning(f"No refresh token available for user {db_user_id} - using CLIENT_MANAGED")
        
        # Store ID token if provided
        if request.id_token:
            encrypted_id_token = encryption_service.encrypt(request.id_token)
            await supabase_service.store_encrypted_token(
                user_id=db_user_id,
                token_type="id_token",
                encrypted_token=encrypted_id_token
            )
        
        return StoreTokensResponse(
            message="Tokens stored successfully with server auth code",
            user_id=db_user_id
        )
        
    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to exchange auth code: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to exchange auth code for tokens: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Error storing tokens with auth code: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to store tokens: {str(e)}"
        )
```

### Step 4: Ensure Google Console Configuration

In Google Cloud Console → APIs & Services → Credentials:

1. **OAuth 2.0 Client ID** settings:
   - ✅ Authorized redirect URIs: `http://localhost:3000`
   - ✅ Access type: **Offline** (this is crucial for refresh tokens!)

2. **OAuth Consent Screen**:
   - ✅ Add scope: `https://www.googleapis.com/auth/drive`
   - ✅ Access type: **Offline**

## How It Works After Implementation

### First Sign-In:
```
1. User clicks "Sign in with Google"
2. Frontend gets: access token + server auth code
3. Frontend sends server auth code to backend
4. Backend exchanges code for: REAL refresh token
5. Backend stores: encrypted refresh token
6. ✅ Backend now has long-term access (months!)
```

### After 4 Hours of Inactivity:

#### Frontend:
```
1. User opens app
2. Access token expired (50 min)
3. silentSignIn() → Uses internal refresh token
4. Gets new access token
5. ✅ User stays logged in
```

#### Backend (for background jobs):
```
1. Backend needs to access Drive
2. Access token expired
3. Backend uses stored refresh token
4. Gets new access token from Google
5. ✅ Backend has uninterrupted access
```

## Session Duration

### With Refresh Tokens:
- **Access Token**: 1 hour (auto-refreshed)
- **Refresh Token**: Until revoked (can be months/years!)
- **User Experience**: Never needs to sign in again

### User Stays Logged In Until:
1. ❌ User explicitly signs out
2. ❌ User revokes access in Google Account settings
3. ❌ User changes Google password (sometimes)
4. ❌ Security event on Google account

## Important Notes

### Refresh Token Only Provided Once

Google only provides refresh tokens on **first authorization**. If testing:

1. **To get a new refresh token**, user must:
   - Go to https://myaccount.google.com/permissions
   - Find your app
   - Click "Remove Access"
   - Sign in to your app again (will get refresh token)

2. **Or use `prompt=consent`** in OAuth params to force consent screen every time (not recommended for production)

### Offline Access

Add to `auth_service.dart` initialization:

```dart
_googleSignIn = GoogleSignIn(
  params: GoogleSignInParams(
    clientId: clientId,
    clientSecret: clientSecret,
    scopes: _scopes,
    redirectPort: 3000,
    timeout: const Duration(minutes: 2),
    // Force offline access to get refresh token
    additionalParameters: {
      'access_type': 'offline',
      'prompt': 'consent', // Use only during testing
    },
  ),
);
```

## Testing the Solution

### Test 1: Initial Sign In
```bash
# Watch backend logs
cd backend
python -m uvicorn app.main:app --reload --log-level info

# Expected logs:
# Exchanging server auth code for refresh token...
# Successfully obtained refresh token for user xxx
# Stored real refresh token - backend has long-term access
```

### Test 2: After 4 Hours
1. Sign in to app
2. Close app completely
3. Wait 4 hours (or change system time for testing)
4. Open app
5. Navigate to Files
6. **Expected**: Files load immediately, no sign-in needed

### Test 3: Backend Token Refresh
```bash
# In backend, test token refresh
curl -X POST http://localhost:8000/drive/list-files \
  -H "Content-Type: application/json" \
  -d '{"user_id": "your-google-sub"}'

# Should work even if access token expired
# Backend will use refresh token automatically
```

## Summary

| Feature | Before | After |
|---------|--------|-------|
| Frontend session | ~50 min | Indefinite (until revoked) |
| Backend access | Only when user active | Always (even offline) |
| Token refresh | Frontend only | Frontend + Backend |
| Re-authentication | Every hour | Only if revoked |
| Background jobs | ❌ Fails when user inactive | ✅ Works independently |

## Implementation Checklist

- [ ] Add `storeTokensWithAuthCode()` to `api_service.dart`
- [ ] Update `signInWithGoogle()` to get server auth code
- [ ] Add `/store-tokens-with-auth-code` endpoint to backend
- [ ] Add token exchange logic to backend
- [ ] Configure Google Console for offline access
- [ ] Test: Sign in and check backend logs for "real refresh token"
- [ ] Test: Close app for 4 hours, reopen, verify no re-login needed
- [ ] Test: Backend job accessing Drive after user inactive

Once implemented, your users will stay logged in for weeks/months, and your backend will have uninterrupted access to Drive API! 🎉

