# Payment & Subscription Guide

## 🚀 Quick Start: Upgrading to Premium

### Step-by-Step Instructions

#### 1️⃣ Navigate to Subscription Settings

**On Mobile (Android/iOS):**
1. Tap the **☰ Menu** icon (top-left)
2. Tap **Settings** ⚙️
3. Scroll down to **Subscription** section

**On Desktop (Windows/Mac/Linux):**
1. Click **Settings** in the sidebar
2. Scroll to **Subscription** section

**On Web:**
1. Click your profile icon (top-right)
2. Select **Settings**
3. Navigate to **Subscription** tab

#### 2️⃣ Check Your Current Plan

You'll see one of two states:

**Free Plan:**
```
┌─────────────────────────────┐
│ 📦 Current Plan: Free       │
│                             │
│ ✅ Basic features           │
│ ✅ Offline access           │
│ ✅ Google Drive sync        │
│                             │
│ [Upgrade to Premium] 🚀     │
└─────────────────────────────┘
```

**Premium Plan:**
```
┌─────────────────────────────┐
│ ⭐ Current Plan: Premium    │
│                             │
│ Activated: Jan 15, 2025     │
│ Expires: Jan 15, 2026       │
│                             │
│ ✅ All Premium features     │
└─────────────────────────────┘
```

#### 3️⃣ Click "Upgrade to Premium"

This will take you to the payment method selection screen.

---

## 💳 Payment Methods

### Option 1: bKash Payment

**Best for:** Bangladesh users with bKash mobile wallet

**Steps:**

1. **Select bKash** on the payment method screen
   ```
   ┌─────────────────────────────┐
   │  📱 bKash                   │
   │  Mobile wallet payment      │
   │  [Select] →                 │
   └─────────────────────────────┘
   ```

2. **Enter your details:**
   - **Mobile Number:** Your 11-digit bKash number (e.g., 01712345678)
   - **PIN:** Your 5-digit bKash PIN

3. **Review payment:**
   - Amount: 500 BDT
   - Service: ScholarMate Premium (1 Year)

4. **Click "Pay Now"**

5. **Wait for confirmation** (usually 1-2 seconds)

**Demo Test Credentials:**
- Mobile: Any number starting with `01` (11 digits)
- PIN: `12345`

**Example:**
```
Mobile Number: 01712345678
PIN: 12345
Amount: 500 BDT
```

---

### Option 2: Debit Card Payment

**Best for:** Users with Visa/Mastercard debit cards

**Steps:**

1. **Select Debit Card** on the payment method screen
   ```
   ┌─────────────────────────────┐
   │  💳 Debit Card              │
   │  Visa, Mastercard           │
   │  [Select] →                 │
   └─────────────────────────────┘
   ```

2. **Enter card details:**
   - **Card Number:** 16-digit number on your card
   - **Expiry Date:** MM/YY format (e.g., 12/25)
   - **CVV:** 3-digit security code on back

3. **Review payment:**
   - Amount: 500 BDT
   - Service: ScholarMate Premium (1 Year)

4. **Click "Pay Now"**

5. **Wait for confirmation**

**Demo Test Credentials:**
```
Card Number: 4111 1111 1111 1111
Expiry Date: 12/25 (any future date)
CVV: 123
Amount: 500 BDT
```

**Card Number Formatting:**
- Spaces are automatically added as you type
- Format: `4111 1111 1111 1111`

---

### Option 3: Credit Card Payment

**Best for:** Users with Visa/Mastercard credit cards

**Steps:**

1. **Select Credit Card** on the payment method screen
   ```
   ┌─────────────────────────────┐
   │  💳 Credit Card             │
   │  Visa, Mastercard           │
   │  [Select] →                 │
   └─────────────────────────────┘
   ```

2. **Enter card details:**
   - **Card Number:** 16-digit number on your card
   - **Expiry Date:** MM/YY format
   - **CVV:** 3-digit security code

3. **Review and pay** (same as debit card)

**Demo Test Credentials:**
```
Card Number: 4111 1111 1111 1111
Expiry Date: 12/25
CVV: 123
```

---

## ✅ Payment Success

### What You'll See

After successful payment, you'll see:

```
┌─────────────────────────────────┐
│  ✅ Payment Successful!         │
│                                 │
│  🎉 Premium Activated!          │
│                                 │
│  Transaction ID:                │
│  TXN_A1B2C3D4E5F6               │
│                                 │
│  Amount Paid: 500 BDT           │
│  Valid Until: Jan 15, 2026      │
│                                 │
│  [Back to Settings]             │
└─────────────────────────────────┘
```

### What Happens Next

1. ✅ **Instant Activation:** Premium features unlock immediately
2. ✅ **Transaction Record:** Payment saved to your history
3. ✅ **Subscription Active:** Valid for 1 year from today
4. ✅ **All Devices:** Premium status syncs across all your devices

### Save Your Transaction ID

**Important:** Note down your transaction ID for future reference:
- Use it for support inquiries
- Reference for payment verification
- Proof of purchase

**Example Transaction ID:** `TXN_A1B2C3D4E5F6`

---

## ❌ Payment Failed

### What You'll See

If payment fails, you'll see:

```
┌─────────────────────────────────┐
│  ❌ Payment Failed              │
│                                 │
│  Transaction ID:                │
│  TXN_X9Y8Z7W6V5U4               │
│                                 │
│  Reason:                        │
│  Invalid payment credentials    │
│                                 │
│  [Retry Payment]                │
│  [Back to Settings]             │
└─────────────────────────────────┘
```

### Common Reasons for Failure

**For Demo System:**
- ❌ Incorrect test credentials
- ❌ Wrong PIN/CVV
- ❌ Invalid card number format
- ❌ Expired card date

**For Production System:**
- ❌ Insufficient balance
- ❌ Card declined by bank
- ❌ Incorrect PIN/CVV
- ❌ Network timeout
- ❌ Payment gateway error

### How to Retry

**Option 1: Retry from Failed Screen**
1. Click **"Retry Payment"** button
2. You'll return to the payment form
3. Verify your details
4. Try again

**Option 2: Retry from Payment History**
1. Go to Settings → Subscription
2. Scroll to **Payment History**
3. Find the failed transaction
4. Click **"Retry"** button next to it

---

## 📊 Payment History

### Viewing Your Transactions

**Location:** Settings → Subscription → Payment History

**What You'll See:**

```
┌─────────────────────────────────────────────┐
│  Payment History                            │
├─────────────────────────────────────────────┤
│                                             │
│  ✅ TXN_A1B2C3D4E5F6                        │
│  bKash • 500 BDT                            │
│  Jan 15, 2025 at 10:30 AM                  │
│  Status: Success                            │
│                                             │
│  ❌ TXN_X9Y8Z7W6V5U4                        │
│  Credit Card • 500 BDT                      │
│  Jan 14, 2025 at 3:45 PM                   │
│  Status: Failed                             │
│  [Retry]                                    │
│                                             │
│  ⏳ TXN_P0O9I8U7Y6T5                        │
│  Debit Card • 500 BDT                       │
│  Jan 13, 2025 at 9:15 AM                   │
│  Status: Pending                            │
│                                             │
└─────────────────────────────────────────────┘
```

### Transaction Details

Each transaction shows:
- 🆔 **Transaction ID:** Unique identifier
- 💳 **Payment Method:** bKash, Debit Card, or Credit Card
- 💰 **Amount:** Payment amount in BDT
- 📅 **Date & Time:** When payment was attempted
- ✅ **Status:** Success, Failed, or Pending

### Transaction Statuses

| Status | Icon | Meaning |
|--------|------|---------|
| Success | ✅ | Payment completed, Premium activated |
| Failed | ❌ | Payment rejected, can retry |
| Pending | ⏳ | Payment processing, wait or contact support |

---

## 🔐 Security & Privacy

### Payment Data Protection

**What We Store:**
- ✅ Transaction ID
- ✅ Payment method type (bKash/Card)
- ✅ Amount and currency
- ✅ Transaction status
- ✅ Date and time

**What We DON'T Store:**
- ❌ Card numbers
- ❌ CVV codes
- ❌ PINs
- ❌ Expiry dates
- ❌ Any sensitive payment credentials

### Secure Connection

- 🔒 All payment data transmitted over HTTPS
- 🔒 End-to-end encryption
- 🔒 No payment data stored on device
- 🔒 Secure backend validation

### Privacy

- Your payment history is private
- Only you can see your transactions
- Not shared with third parties
- Protected by Row Level Security (RLS)

---

## 💡 Tips & Best Practices

### Before Making Payment

1. ✅ **Check your internet connection**
   - Stable connection required
   - Avoid switching networks during payment

2. ✅ **Verify payment details**
   - Double-check card number
   - Confirm expiry date is future
   - Ensure correct CVV/PIN

3. ✅ **Have sufficient balance**
   - Check account balance
   - Ensure credit limit available

4. ✅ **Use supported payment methods**
   - bKash, Debit Card, or Credit Card
   - Visa or Mastercard for cards

### During Payment

1. ⏳ **Wait for confirmation**
   - Don't close the app
   - Don't press back button
   - Wait for success/failure screen

2. 🔄 **Don't retry immediately**
   - Wait for current attempt to complete
   - Check payment history first

3. 📱 **Keep device active**
   - Prevent screen timeout
   - Don't switch apps

### After Payment

1. 📸 **Screenshot confirmation**
   - Save transaction ID
   - Keep for your records

2. ✅ **Verify Premium activation**
   - Check Settings → Subscription
   - Confirm Premium status

3. 📧 **Check email** (if configured)
   - Look for confirmation email
   - Save for records

---

## 🌐 Platform-Specific Instructions

### Android

**Payment Flow:**
1. Open app → Menu → Settings → Subscription
2. Tap "Upgrade to Premium"
3. Select payment method
4. Enter details using on-screen keyboard
5. Tap "Pay Now"
6. Wait for confirmation

**Tips:**
- Use autofill for card details (if enabled)
- Ensure stable WiFi or mobile data
- Keep app in foreground during payment

### iOS

**Payment Flow:**
1. Open app → Settings → Subscription
2. Tap "Upgrade to Premium"
3. Select payment method
4. Enter details
5. Tap "Pay Now"
6. Wait for confirmation

**Tips:**
- Face ID/Touch ID not required (demo system)
- Ensure good network connection
- Don't lock device during payment

### Web

**Payment Flow:**
1. Click profile icon → Settings → Subscription
2. Click "Upgrade to Premium"
3. Select payment method
4. Enter details (browser autofill supported)
5. Click "Pay Now"
6. Wait for confirmation

**Tips:**
- Use modern browser (Chrome, Firefox, Safari, Edge)
- Enable JavaScript
- Don't close browser tab during payment

### Windows/Mac/Linux

**Payment Flow:**
1. Open Settings → Subscription
2. Click "Upgrade to Premium"
3. Select payment method
4. Enter details
5. Click "Pay Now"
6. Wait for confirmation

**Tips:**
- Ensure stable internet connection
- Don't minimize window during payment
- Use keyboard shortcuts for faster input

---

## 🆘 Troubleshooting

### Payment Button Disabled

**Reason:** Form validation failed

**Solution:**
1. Check all fields are filled
2. Verify correct format:
   - bKash: 11 digits starting with 01
   - Card: 16 digits
   - CVV: 3 digits
   - Expiry: MM/YY format, future date
3. Fix any validation errors shown
4. Button will enable automatically

### "Transaction Not Found" Error

**Reason:** Transaction ID invalid or expired

**Solution:**
1. Start a new payment attempt
2. Don't reuse old transaction IDs
3. Contact support if issue persists

### Payment Stuck on "Processing"

**Reason:** Network timeout or server delay

**Solution:**
1. Wait 30 seconds
2. Check payment history
3. If not listed, retry payment
4. If listed as pending, wait or contact support

### "Invalid Credentials" Error

**For Demo System:**
- Use test credentials exactly as specified
- bKash PIN must be `12345`
- Card number must be `4111111111111111`
- CVV must be `123`

**For Production System:**
- Verify credentials with your bank
- Check card is not expired
- Ensure sufficient balance
- Contact bank if issue persists

---

## 📞 Getting Help

### Self-Service Resources

1. **FAQ:** See `SUBSCRIPTION_FAQ.md`
2. **Troubleshooting:** See `SUBSCRIPTION_TROUBLESHOOTING.md`
3. **In-App Help:** Settings → Help & Support

### Contact Support

**When to contact:**
- Payment succeeded but Premium not activated
- Charged but transaction shows failed
- Technical errors during payment
- Questions about subscription

**What to include:**
- Transaction ID
- Payment method used
- Date and time
- Screenshots
- Device and app version

**Response Time:**
- Demo system: Contact instructor/supervisor
- Production system: 24-48 hours

---

## ⚠️ Important Notes

### Demo System Disclaimer

**This is a demonstration/mock payment system:**
- ✅ Showcases payment flow and UI
- ✅ Demonstrates subscription management
- ✅ Uses test credentials only
- ❌ Does NOT process real payments
- ❌ Does NOT charge real money
- ❌ Not suitable for production use

### Production Deployment

For real payment processing, this system must be integrated with:
- **SSLCommerz** (Bangladesh)
- **bKash Official API** (Bangladesh)
- **Stripe** (International)
- **PayPal** (International)

### Test Credentials Reminder

**bKash:**
- Mobile: `01XXXXXXXXX` (any 11 digits starting with 01)
- PIN: `12345`

**Card:**
- Number: `4111 1111 1111 1111`
- CVV: `123`
- Expiry: Any future date

---

## 📚 Additional Resources

- **FAQ:** `SUBSCRIPTION_FAQ.md`
- **Troubleshooting:** `SUBSCRIPTION_TROUBLESHOOTING.md`
- **Technical Documentation:** `.kiro/specs/payment-subscription-system/`
- **API Documentation:** Backend Swagger UI at `http://localhost:8000/docs`

---

**Last Updated:** November 2025  
**Version:** 1.0 (Demo)  
**Support:** For demo/academic use only
