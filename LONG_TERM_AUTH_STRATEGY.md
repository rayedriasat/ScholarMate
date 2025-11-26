# Long-Term Authentication Strategy

## How Google Sign-In Maintains Persistent Access

### The Platform-Managed Approach

The `google_sign_in_all_platforms` package uses **platform-specific secure storage** to manage refresh tokens:

- **Android/iOS**: OS keychain stores the refresh token
- **Web**: Browser session/cookies store credentials
- **Windows/Linux**: Platform credential manager stores tokens

### Why You Don't See Refresh Tokens

When you call `credentials.refreshToken`, it's often `null` because:
1. The refresh token is stored securely by the platform
2. The package accesses it internally when needed
3. You don't need to manually manage it

### How Long-Term Access Works

```
User Signs In (First Time)
    ↓
Google issues refresh token
    ↓
Platform stores it securely (invisible to your app)
    ↓
App gets access token (expires in ~1 hour)
    ↓
App closes / User returns later
    ↓
Call silentSignIn()
    ↓
Package uses stored refresh token automatically
    ↓
New access token issued (no user interaction needed)
```

### Implementation in AuthService

#### 1. Initial Sign-In
```dart
// User clicks sign-in button
final user = await authService.signInWithGoogle();
// Refresh token stored by platform (you don't see it)
```

#### 2. App Restart
```dart
// On app startup
await authService.initialize(...);
// Automatically calls silentSignIn() if user was previously signed in
// Gets fresh access token using stored refresh token
```

#### 3. Token Refresh (Automatic)
```dart
// When making Drive API calls
final token = await authService.getAccessToken();
// If token expired, automatically calls silentSignIn()
// Returns fresh token without user interaction
```

### Key Methods

#### `silentSignIn()`
- Uses platform-stored refresh token
- Gets new access token without user interaction
- Returns null if refresh token expired/revoked
- **This is your primary refresh mechanism**

#### `getAccessToken()`
- Checks if current token is expired
- Automatically calls `silentSignIn()` if needed
- Returns fresh token or null

### When Users Need to Re-Authenticate

Users only need to sign in again if:
1. They explicitly sign out
2. They revoke app permissions in Google Account settings
3. Refresh token expires (typically after 6 months of inactivity)
4. Platform credential storage is cleared

### Best Practices

#### ✅ DO
- Call `silentSignIn()` on app startup
- Let `getAccessToken()` handle token refresh automatically
- Trust the platform's secure storage
- Handle null tokens gracefully (prompt re-login)

#### ❌ DON'T
- Try to manually refresh tokens via HTTP
- Store refresh tokens in your own database
- Assume `credentials.refreshToken` will always be populated
- Implement custom token refresh logic

### Testing Long-Term Access

1. **Sign in** to the app
2. **Close** the app completely
3. **Wait** 1+ hours (access token expires)
4. **Reopen** the app
5. **Verify** you're still signed in (silentSignIn worked)
6. **Make Drive API call** (should work without re-login)

### Troubleshooting

#### "User needs to sign in again after app restart"
- Check that `silentSignIn()` is called in `initialize()`
- Verify scopes haven't changed (scope changes require re-consent)
- Ensure platform credential storage isn't being cleared

#### "Token refresh fails"
- User may have revoked permissions
- Refresh token may have expired (6 months inactivity)
- Prompt user to sign in again

#### "Access token expires too quickly"
- This is normal (1 hour expiry)
- `getAccessToken()` handles refresh automatically
- Don't cache tokens for long periods

### Code Flow Summary

```dart
// App Startup
await authService.initialize(clientId: '...');
// → Calls silentSignIn() if user was previously signed in
// → Gets fresh access token using platform-stored refresh token

// Making API Calls
final token = await authService.getAccessToken();
// → Checks if token expired
// → Calls silentSignIn() if needed
// → Returns fresh token

// User Signs Out
await authService.signOut();
// → Clears platform-stored credentials
// → User needs to sign in again next time
```

### Security Benefits

1. **Refresh tokens never exposed** to your app code
2. **Platform-level encryption** protects credentials
3. **Automatic token rotation** reduces attack surface
4. **Revocation** works immediately (platform checks with Google)

### Conclusion

You don't need to explicitly manage refresh tokens. The package and platform handle everything. Just:
1. Call `silentSignIn()` on startup
2. Use `getAccessToken()` for API calls
3. Handle null gracefully (prompt re-login)

This provides secure, long-term access without manual token management.
