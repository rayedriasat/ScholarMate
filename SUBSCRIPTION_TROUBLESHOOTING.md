# Subscription & Payment Troubleshooting Guide

## 🔍 Quick Diagnosis

### Identify Your Issue

| Symptom | Section | Quick Fix |
|---------|---------|-----------|
| Payment button won't enable | [Form Validation](#form-validation-issues) | Check all fields are filled correctly |
| Payment fails immediately | [Payment Failures](#payment-failure-issues) | Verify test credentials |
| Payment stuck processing | [Processing Issues](#payment-processing-issues) | Wait 30s, check history |
| Premium not activated | [Activation Issues](#premium-activation-issues) | Restart app, check status |
| Can't see payment history | [History Issues](#payment-history-issues) | Check internet, refresh |
| App crashes during payment | [App Crashes](#app-crash-issues) | Update app, clear cache |

---

## 🔧 Form Validation Issues

### Problem: "Pay Now" Button is Disabled

**Symptoms:**
- Button appears grayed out
- Can't click to submit payment
- No error message shown

**Causes & Solutions:**

#### 1. Incomplete Form Fields

**Check:**
- All required fields filled?
- No empty fields?

**Solution:**
```
bKash Form:
✅ Mobile Number: [filled]
✅ PIN: [filled]
✅ Amount: [auto-filled]

Card Form:
✅ Card Number: [filled]
✅ Expiry Date: [filled]
✅ CVV: [filled]
✅ Amount: [auto-filled]
```

#### 2. Invalid Mobile Number Format (bKash)

**Check:**
- Starts with `01`?
- Exactly 11 digits?
- No spaces or dashes?

**Invalid Examples:**
- ❌ `1712345678` (missing leading 0)
- ❌ `017123456` (too short)
- ❌ `01712-345678` (contains dash)
- ❌ `+8801712345678` (contains country code)

**Valid Examples:**
- ✅ `01712345678`
- ✅ `01812345678`
- ✅ `01912345678`

**Solution:**
```
Enter exactly 11 digits starting with 01
Example: 01712345678
```

#### 3. Invalid Card Number Format

**Check:**
- Exactly 16 digits?
- Valid card number (Luhn algorithm)?
- No letters or special characters?

**Invalid Examples:**
- ❌ `4111 1111 1111 111` (too short)
- ❌ `4111-1111-1111-1111` (dashes not allowed)
- ❌ `1234 5678 9012 3456` (fails Luhn check)

**Valid Example:**
- ✅ `4111 1111 1111 1111` (spaces auto-added)

**Solution:**
```
For demo: Use 4111111111111111
Spaces are added automatically as you type
```

#### 4. Invalid CVV Format

**Check:**
- Exactly 3 digits?
- Numbers only?

**Invalid Examples:**
- ❌ `12` (too short)
- ❌ `1234` (too long)
- ❌ `12A` (contains letter)

**Valid Example:**
- ✅ `123`

**Solution:**
```
For demo: Use 123
Enter exactly 3 digits
```

#### 5. Invalid Expiry Date

**Check:**
- Format is MM/YY?
- Date is in the future?
- Month is 01-12?

**Invalid Examples:**
- ❌ `13/25` (month > 12)
- ❌ `12/20` (past date)
- ❌ `12/2025` (wrong format)
- ❌ `1/25` (missing leading zero)

**Valid Examples:**
- ✅ `12/25`
- ✅ `06/26`
- ✅ `01/30`

**Solution:**
```
Format: MM/YY
Example: 12/25
Must be a future date
```

#### 6. Invalid PIN Format (bKash)

**Check:**
- Exactly 5 digits?
- Numbers only?

**Invalid Examples:**
- ❌ `1234` (too short)
- ❌ `123456` (too long)
- ❌ `12A45` (contains letter)

**Valid Example:**
- ✅ `12345` (for demo)

**Solution:**
```
For demo: Use 12345
Enter exactly 5 digits
```

---

## ❌ Payment Failure Issues

### Problem: Payment Fails with "Invalid Credentials"

**Symptoms:**
- Payment processes but fails
- Error message: "Invalid credentials"
- Redirected to failure screen

**For Demo System:**

#### bKash Failures

**Common Mistakes:**

1. **Wrong PIN**
   ```
   ❌ PIN: 54321 (reversed)
   ❌ PIN: 11111 (wrong)
   ✅ PIN: 12345 (correct)
   ```

2. **Wrong Mobile Format**
   ```
   ❌ Mobile: 1712345678 (missing 0)
   ❌ Mobile: +8801712345678 (has country code)
   ✅ Mobile: 01712345678 (correct)
   ```

**Solution:**
```
Use EXACTLY these test credentials:
Mobile: 01XXXXXXXXX (any 11 digits starting with 01)
PIN: 12345
```

#### Card Payment Failures

**Common Mistakes:**

1. **Wrong Card Number**
   ```
   ❌ Card: 4111 1111 1111 1112 (wrong last digit)
   ❌ Card: 5111 1111 1111 1111 (wrong first digit)
   ✅ Card: 4111 1111 1111 1111 (correct)
   ```

2. **Wrong CVV**
   ```
   ❌ CVV: 321 (reversed)
   ❌ CVV: 456 (wrong)
   ✅ CVV: 123 (correct)
   ```

3. **Expired Date**
   ```
   ❌ Expiry: 12/20 (past)
   ❌ Expiry: 01/24 (past)
   ✅ Expiry: 12/25 (future)
   ```

**Solution:**
```
Use EXACTLY these test credentials:
Card Number: 4111 1111 1111 1111
CVV: 123
Expiry: 12/25 (or any future date)
```

### Problem: Payment Fails with "Transaction Not Found"

**Symptoms:**
- Error during verification
- Transaction ID not recognized

**Causes:**
1. Transaction expired (>30 minutes old)
2. Invalid transaction ID
3. Database connection issue

**Solution:**
1. Start a new payment attempt
2. Don't reuse old transaction IDs
3. Complete payment within 30 minutes
4. Check internet connection

### Problem: Payment Fails with Network Error

**Symptoms:**
- "Network error" message
- "Connection timeout"
- "Unable to reach server"

**Causes:**
1. No internet connection
2. Weak signal
3. Backend server down
4. Firewall blocking

**Solution:**

**Step 1: Check Internet**
```
✅ WiFi connected?
✅ Mobile data enabled?
✅ Signal strength good?
✅ Can browse other apps?
```

**Step 2: Test Connection**
```
1. Open browser
2. Visit google.com
3. If loads → internet OK
4. If fails → fix internet first
```

**Step 3: Retry Payment**
```
1. Ensure stable connection
2. Close other apps
3. Retry payment
4. Stay on payment screen
```

**Step 4: Check Backend (Developers)**
```
1. Visit http://localhost:8000/docs
2. If loads → backend OK
3. If fails → start backend server
4. Command: uv run python run.py
```

---

## ⏳ Payment Processing Issues

### Problem: Payment Stuck on "Processing"

**Symptoms:**
- Loading spinner indefinitely
- No success or failure screen
- Can't proceed or go back

**Immediate Actions:**

**Wait First (30 seconds):**
```
⏱️ 0-10s: Normal processing time
⏱️ 10-20s: Possible network delay
⏱️ 20-30s: Check connection
⏱️ 30s+: Take action
```

**After 30 Seconds:**

1. **Check Payment History**
   ```
   1. Open new app instance (don't close current)
   2. Go to Settings → Subscription
   3. Check Payment History
   4. Look for recent transaction
   ```

2. **If Transaction Exists:**
   ```
   Status: Success → Close stuck screen, Premium should be active
   Status: Failed → Close stuck screen, retry payment
   Status: Pending → Wait 5 more minutes, then contact support
   ```

3. **If No Transaction:**
   ```
   1. Close app completely
   2. Reopen app
   3. Check subscription status
   4. If still Free, retry payment
   ```

### Problem: Multiple Failed Attempts

**Symptoms:**
- Payment fails repeatedly
- Same error each time
- Tried multiple times

**Diagnostic Steps:**

**Step 1: Verify Test Credentials**
```
Print out test credentials:
bKash: 01XXXXXXXXX / 12345
Card: 4111111111111111 / 123 / 12/25

Copy-paste if possible (no typos)
```

**Step 2: Check App Version**
```
Settings → About
Version should be: 1.0.0 or higher
If older → Update app
```

**Step 3: Clear App Cache**
```
Android:
Settings → Apps → ScholarMate → Storage → Clear Cache

iOS:
Settings → General → iPhone Storage → ScholarMate → Offload App

Windows:
Settings → Clear Cache button

Web:
Browser → Clear Site Data
```

**Step 4: Reinstall App (Last Resort)**
```
1. Backup your data (Google Drive sync)
2. Uninstall app
3. Reinstall from store
4. Sign in again
5. Try payment
```

---

## 🚫 Premium Activation Issues

### Problem: Payment Succeeded but Premium Not Activated

**Symptoms:**
- Payment shows "Success" in history
- Transaction ID received
- Still shows "Free" plan
- Premium features locked

**Diagnostic Steps:**

**Step 1: Verify Transaction**
```
1. Go to Settings → Subscription
2. Check Payment History
3. Find your transaction
4. Confirm status is "Success" ✅
5. Note the Transaction ID
```

**Step 2: Force Refresh**
```
1. Pull down on Subscription screen (refresh)
2. Wait 5 seconds
3. Check plan status again
```

**Step 3: Restart App**
```
1. Close app completely (swipe away)
2. Wait 10 seconds
3. Reopen app
4. Check Settings → Subscription
```

**Step 4: Check Sync Status**
```
1. Ensure internet connected
2. Look for sync indicator
3. Wait for sync to complete
4. Check subscription status
```

**Step 5: Manual Verification (Developers)**
```
1. Open backend logs
2. Search for transaction ID
3. Check subscription_status in database
4. Verify user record updated
```

**If Still Not Activated:**
```
Contact support with:
- Transaction ID
- Screenshot of success screen
- Screenshot of subscription status
- Device and app version
```

### Problem: Premium Activated but Features Still Locked

**Symptoms:**
- Subscription shows "Premium"
- Expiry date is future
- But premium features don't work

**Causes:**
1. App cache not refreshed
2. Feature flags not updated
3. Sync delay

**Solution:**

**Step 1: Force App Restart**
```
1. Close app completely
2. Clear from recent apps
3. Wait 10 seconds
4. Reopen app
```

**Step 2: Check Feature Access**
```
Try each premium feature:
✅ AI queries unlimited?
✅ Advanced search working?
✅ Premium badge showing?
```

**Step 3: Re-sync**
```
1. Go to Settings
2. Pull down to refresh
3. Wait for sync complete
4. Try features again
```

**Step 4: Check Backend (Developers)**
```
1. Verify subscription_status = 'premium'
2. Check subscription_expires_at > now
3. Verify feature flags in code
4. Check RLS policies
```

---

## 📊 Payment History Issues

### Problem: Can't See Payment History

**Symptoms:**
- Payment History section empty
- "No transactions" message
- But you made payments

**Causes:**
1. Not signed in
2. Wrong account
3. Network issue
4. Database sync delay

**Solution:**

**Step 1: Verify Sign In**
```
1. Check profile icon shows your photo
2. Verify correct email displayed
3. If wrong account → Sign out and sign in with correct account
```

**Step 2: Check Internet**
```
1. Ensure connected to internet
2. Try loading other screens
3. If offline → Connect and retry
```

**Step 3: Force Refresh**
```
1. Pull down on Subscription screen
2. Wait for refresh animation
3. Check history again
```

**Step 4: Check Database (Developers)**
```
1. Query transactions table
2. Filter by user_id
3. Verify records exist
4. Check RLS policies allow access
```

### Problem: Transaction Shows Wrong Status

**Symptoms:**
- Payment succeeded but shows "Failed"
- Payment failed but shows "Success"
- Status is "Pending" for hours

**For "Pending" Status:**

**If < 5 minutes old:**
```
⏱️ Wait - payment may still be processing
```

**If 5-30 minutes old:**
```
1. Refresh payment history
2. Check subscription status
3. If Premium activated → ignore pending status
4. If still Free → contact support
```

**If > 30 minutes old:**
```
1. Note transaction ID
2. Check bank/bKash statement
3. Contact support with:
   - Transaction ID
   - Time of payment
   - Current status shown
   - Bank confirmation (if charged)
```

**For Wrong Status:**
```
1. Screenshot the incorrect status
2. Note transaction ID
3. Check subscription status
4. Contact support with evidence
```

---

## 💥 App Crash Issues

### Problem: App Crashes During Payment

**Symptoms:**
- App closes suddenly
- Returns to home screen
- Payment interrupted

**Immediate Actions:**

**Step 1: Reopen App**
```
1. Tap app icon
2. Wait for app to load
3. Sign in if needed
```

**Step 2: Check Payment Status**
```
1. Go to Settings → Subscription
2. Check Payment History
3. Look for recent transaction
```

**Step 3: Determine Next Action**
```
If transaction exists:
  Status = Success → Premium should be active ✅
  Status = Failed → Retry payment ❌
  Status = Pending → Wait 5 minutes ⏳

If no transaction:
  → Payment didn't process
  → Safe to retry
```

**Prevent Future Crashes:**

**Step 1: Update App**
```
1. Check app store for updates
2. Install latest version
3. Restart device
4. Try payment again
```

**Step 2: Free Up Memory**
```
1. Close other apps
2. Clear app cache
3. Restart device
4. Try payment with only ScholarMate open
```

**Step 3: Check Device Storage**
```
Ensure at least 500MB free:
Android: Settings → Storage
iOS: Settings → General → iPhone Storage
Windows: Settings → System → Storage
```

### Problem: App Freezes During Payment

**Symptoms:**
- Screen unresponsive
- Can't tap buttons
- No loading indicator

**Solution:**

**Step 1: Wait (30 seconds)**
```
⏱️ App may be processing
⏱️ Don't force close immediately
```

**Step 2: Force Close (if still frozen)**
```
Android: Recent apps → Swipe away
iOS: Swipe up → Swipe away
Windows: Alt+F4 or Task Manager
```

**Step 3: Check Payment Status**
```
(Same as crash scenario above)
```

**Step 4: Report Issue**
```
If happens repeatedly:
1. Note exact step where freeze occurs
2. Check device specs meet requirements
3. Try on different device
4. Report to support with:
   - Device model
   - OS version
   - App version
   - Steps to reproduce
```

---

## 🌐 Platform-Specific Issues

### Android Issues

#### Problem: Payment Form Not Showing Keyboard

**Solution:**
```
1. Tap input field again
2. If still no keyboard → Restart app
3. Check keyboard is enabled in Android settings
4. Try different keyboard app
```

#### Problem: Back Button Exits Payment

**Solution:**
```
1. Use in-app back button (top-left)
2. Don't use Android system back button during payment
3. If accidentally exited → Check payment history
```

#### Problem: App Permissions Denied

**Solution:**
```
Settings → Apps → ScholarMate → Permissions
Enable:
✅ Internet
✅ Network state
```

### iOS Issues

#### Problem: Payment Form Keyboard Covers Button

**Solution:**
```
1. Scroll down to see Pay Now button
2. Or tap "Done" on keyboard first
3. Then tap Pay Now
```

#### Problem: Face ID Prompt Appears

**Solution:**
```
1. This is normal for iOS
2. Authenticate or cancel
3. Payment will proceed either way (demo system)
```

### Web Issues

#### Problem: Payment Page Not Loading

**Solution:**
```
1. Check browser console for errors (F12)
2. Disable browser extensions
3. Try incognito/private mode
4. Try different browser
5. Clear browser cache
```

#### Problem: Form Autofill Not Working

**Solution:**
```
1. Enable autofill in browser settings
2. Or manually enter test credentials
3. Copy-paste to avoid typos
```

### Windows/Desktop Issues

#### Problem: Window Minimizes During Payment

**Solution:**
```
1. Keep window in focus
2. Don't switch apps during payment
3. If minimized → Restore and check payment history
```

#### Problem: High DPI Display Issues

**Solution:**
```
1. Right-click app → Properties
2. Compatibility → Change high DPI settings
3. Override high DPI scaling
4. Restart app
```

---

## 🔍 Advanced Troubleshooting

### For Developers

#### Check Backend Logs

```bash
# View backend logs
cd backend
uv run python run.py

# Look for errors related to:
- Payment initialization
- Payment verification
- Subscription activation
- Transaction recording
```

#### Check Database

```sql
-- Check user subscription status
SELECT id, email, subscription_status, subscription_activated_at, subscription_expires_at
FROM users
WHERE email = 'user@example.com';

-- Check transactions
SELECT transaction_id, payment_method, amount, status, created_at
FROM transactions
WHERE user_id = 'user-uuid'
ORDER BY created_at DESC;

-- Check for pending transactions
SELECT * FROM transactions
WHERE status = 'pending'
AND created_at < NOW() - INTERVAL '30 minutes';
```

#### Test API Endpoints

```bash
# Test payment initialization
curl -X POST http://localhost:8000/api/payments/initialize \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user",
    "payment_method": "bkash",
    "amount": 500,
    "currency": "BDT"
  }'

# Test subscription status
curl http://localhost:8000/api/payments/subscription-status?user_id=test-user
```

#### Check Frontend Logs

```dart
// Add debug logging in subscription_service.dart
print('Payment init response: $response');
print('Subscription status: $_currentStatus');
print('Payment history: $_paymentHistory');
```

#### Verify Environment Variables

```bash
# Backend
cat backend/.env | grep PAYMENT

# Should show:
# PAYMENT_GATEWAY_TYPE=mock
# PAYMENT_CURRENCY=BDT

# Frontend
cat frontend/dart_defines.json | grep PAYMENT

# Should show:
# "PAYMENT_ENABLED": "true"
# "PREMIUM_PRICE": "500"
# "PREMIUM_CURRENCY": "BDT"
```

---

## 📞 When to Contact Support

### Contact Support If:

1. ✅ **Payment succeeded but Premium not activated after 1 hour**
   - Include: Transaction ID, screenshots

2. ✅ **Charged but transaction shows failed**
   - Include: Bank statement, transaction ID

3. ✅ **App crashes repeatedly during payment**
   - Include: Device model, OS version, crash logs

4. ✅ **Payment history not loading for 24+ hours**
   - Include: Account email, last successful sync time

5. ✅ **Premium features not working despite active subscription**
   - Include: Subscription screenshot, feature attempted

### Don't Contact Support For:

1. ❌ **Wrong test credentials in demo system**
   - Solution: Use correct test credentials from guide

2. ❌ **Form validation errors**
   - Solution: Fix input format per validation rules

3. ❌ **Network connectivity issues**
   - Solution: Fix internet connection first

4. ❌ **App not updated**
   - Solution: Update app from store

5. ❌ **Questions about features**
   - Solution: Check FAQ first

### Support Information

**For Demo/Academic System:**
- Contact: Your instructor or project supervisor
- Include: Transaction ID, screenshots, error messages

**For Production System:**
- Email: support@scholarmate.app
- In-app: Settings → Help & Support
- Response time: 24-48 hours

**What to Include:**
```
Subject: Payment Issue - [Brief Description]

Body:
- Transaction ID: TXN_XXXXXXXXXXXX
- Payment Method: bKash/Card
- Date & Time: YYYY-MM-DD HH:MM
- Issue: [Detailed description]
- Steps Taken: [What you tried]
- Device: [Model and OS]
- App Version: [X.X.X]
- Screenshots: [Attached]
```

---

## ✅ Prevention Checklist

### Before Every Payment

- [ ] Internet connection stable
- [ ] App updated to latest version
- [ ] Sufficient device storage (500MB+)
- [ ] Correct test credentials ready
- [ ] No other apps running (mobile)
- [ ] Device not in power-saving mode

### During Payment

- [ ] Stay on payment screen
- [ ] Don't switch apps
- [ ] Don't lock device
- [ ] Don't press back button
- [ ] Wait for confirmation
- [ ] Keep device active

### After Payment

- [ ] Screenshot confirmation
- [ ] Note transaction ID
- [ ] Verify Premium activation
- [ ] Check payment history
- [ ] Test premium features

---

## 📚 Additional Resources

- **FAQ:** `SUBSCRIPTION_FAQ.md` - Common questions
- **Payment Guide:** `SUBSCRIPTION_PAYMENT_GUIDE.md` - Step-by-step instructions
- **Technical Docs:** `.kiro/specs/payment-subscription-system/` - Developer documentation
- **API Docs:** `http://localhost:8000/docs` - Backend API reference

---

## 🔄 Quick Reference: Error Messages

| Error Message | Meaning | Solution |
|---------------|---------|----------|
| "Invalid credentials" | Wrong test credentials | Use exact test credentials |
| "Transaction not found" | Invalid transaction ID | Start new payment |
| "Network error" | No internet | Check connection |
| "Payment failed" | Validation failed | Verify credentials |
| "Insufficient balance" | (Production only) | Add funds to account |
| "Card declined" | (Production only) | Contact bank |
| "Transaction expired" | Took too long | Start new payment |
| "Server error" | Backend issue | Wait and retry |

---

**Last Updated:** November 2025  
**Version:** 1.0 (Demo)  
**For:** ScholarMate Payment & Subscription System
