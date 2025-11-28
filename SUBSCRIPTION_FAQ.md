# Subscription & Payment FAQ

## 📋 General Questions

### What is ScholarMate Premium?

ScholarMate Premium is a paid subscription that unlocks advanced features in ScholarMate, including enhanced AI capabilities, unlimited document processing, and priority support.

**Free Plan includes:**
- ✅ Basic PDF viewing and annotations
- ✅ Markdown editing
- ✅ Google Drive sync
- ✅ Offline access
- ✅ Limited AI queries (with your own API key)

**Premium Plan includes:**
- ✅ Everything in Free Plan
- ✅ Unlimited AI queries
- ✅ Advanced RAG semantic search
- ✅ Priority processing
- ✅ Premium support
- ✅ Early access to new features

### How much does Premium cost?

Premium subscription costs **500 BDT per year** (approximately $4.50 USD).

### Is this a real payment system?

**⚠️ IMPORTANT: This is a demonstration/mock payment system for academic purposes only.**

This payment system is designed to showcase payment flow and subscription management. It uses test credentials and does not process real payments. In a production environment, this would be replaced with real payment gateways like SSLCommerz or bKash Official API.

### What payment methods are supported?

Currently, the demo system supports:
- 💳 **bKash** - Mobile wallet payment
- 💳 **Debit Card** - Visa, Mastercard
- 💳 **Credit Card** - Visa, Mastercard

---

## 💰 Payment Questions

### How do I upgrade to Premium?

1. Open **Settings** in the app
2. Scroll to the **Subscription** section
3. Click the **Upgrade to Premium** button
4. Select your payment method
5. Enter payment details
6. Click **Pay Now**
7. Wait for confirmation

### What are the test credentials for demo payments?

Since this is a demonstration system, use these test credentials:

**For bKash:**
- Mobile Number: `01XXXXXXXXX` (any 11-digit number starting with 01)
- PIN: `12345`

**For Card Payments:**
- Card Number: `4111 1111 1111 1111`
- CVV: `123`
- Expiry Date: Any future date (e.g., `12/25`)

**Note:** Any other credentials will result in a failed payment (by design).

### Is my payment information secure?

In this demonstration system:
- Payment credentials are validated but not stored
- Transaction records are stored for history purposes
- No real financial data is transmitted

In a production system:
- All payment data would be encrypted in transit (HTTPS)
- Payment processing would be handled by PCI-DSS compliant gateways
- No sensitive payment data would be stored on our servers

### How long does payment processing take?

In the demo system, payment verification is instant (1-2 seconds). In a real system, processing times vary:
- bKash: Usually instant to 1 minute
- Card payments: 1-3 minutes
- Bank transfers: 1-24 hours

### What happens after successful payment?

1. ✅ You receive a confirmation screen with transaction ID
2. ✅ Your account is immediately upgraded to Premium
3. ✅ Premium features are unlocked instantly
4. ✅ Transaction appears in your payment history
5. ✅ You can start using Premium features right away

### Can I get a refund?

**For the demo system:** Since no real money is processed, refunds are not applicable.

**For a production system:** Refund policies would typically include:
- 7-day money-back guarantee
- Pro-rated refunds for annual subscriptions
- Contact support for refund requests

---

## 🔄 Subscription Management

### How do I check my subscription status?

1. Open **Settings**
2. Go to **Subscription** section
3. View your current plan (Free or Premium)
4. See activation date and expiry date (if Premium)

### When does my subscription expire?

Premium subscriptions are valid for **1 year** from the activation date. You can view your expiry date in Settings → Subscription.

### Will my subscription auto-renew?

**Currently:** No, subscriptions do not auto-renew. You'll need to manually renew before expiry.

**Future:** Auto-renewal may be added in future updates with advance notification.

### What happens when my subscription expires?

When your Premium subscription expires:
- ❌ Premium features become unavailable
- ✅ Your documents and data remain intact
- ✅ You can continue using Free plan features
- ✅ You can re-subscribe anytime to regain Premium access

### Can I cancel my subscription?

**For the demo system:** You can simply stop using Premium features.

**For a production system:** You would be able to:
- Cancel anytime from Settings
- Continue using Premium until expiry date
- No charges after cancellation

---

## 📊 Payment History

### Where can I view my payment history?

1. Open **Settings**
2. Go to **Subscription** section
3. Scroll to **Payment History**
4. View all past transactions

### What information is shown in payment history?

Each transaction shows:
- 🆔 Transaction ID
- 💳 Payment method used
- 💰 Amount paid
- 📅 Date and time
- ✅ Status (Success/Failed/Pending)

### Can I download payment receipts?

**Currently:** Not available in the demo system.

**Future:** Receipt download feature may be added in production version.

### What if I see a failed payment?

If you see a failed payment in your history:
1. Click the **Retry** button next to the failed transaction
2. Verify your payment credentials
3. Try again with correct test credentials
4. Contact support if issues persist

---

## 🛡️ Security & Privacy

### Is my payment data stored?

**In the demo system:**
- Payment credentials are NOT stored
- Only transaction metadata is stored (amount, method, status)
- Transaction IDs are generated for tracking

**In a production system:**
- Payment processing would be handled by certified payment gateways
- No sensitive card/PIN data would be stored on our servers
- Only transaction references would be kept

### How is my data protected?

- 🔒 All API communication uses HTTPS encryption
- 🔒 User authentication via Google OAuth 2.0
- 🔒 Database access protected by Row Level Security (RLS)
- 🔒 Payment credentials validated but not persisted

### Can others see my payment information?

No. Payment history is private and only visible to:
- The account owner (you)
- System administrators (for support purposes only)

---

## 🆘 Common Issues

### My payment failed. What should I do?

**For demo system:**
1. Verify you're using the correct test credentials
2. Check your internet connection
3. Try again with the test credentials listed above

**For production system:**
1. Verify your payment details are correct
2. Ensure sufficient balance/credit limit
3. Check with your bank/payment provider
4. Contact support if issue persists

### I paid but didn't get Premium access

**Immediate steps:**
1. Check your payment history in Settings → Subscription
2. Look for a successful transaction
3. Restart the app
4. Check subscription status again

**If still not resolved:**
1. Note your transaction ID
2. Contact support with transaction details
3. Support will verify and activate manually if needed

### The payment page is not loading

**Troubleshooting:**
1. Check your internet connection
2. Restart the app
3. Clear app cache (Settings → App Info → Clear Cache)
4. Update to the latest app version
5. Contact support if issue persists

### I was charged but payment shows as failed

**For demo system:** This shouldn't happen as no real charges occur.

**For production system:**
1. Check your bank statement
2. Note the transaction ID from your bank
3. Contact support immediately with:
   - Transaction ID from bank
   - Amount charged
   - Date and time
   - Screenshot of payment history
4. Support will investigate and resolve within 24-48 hours

---

## 📞 Support

### How do I contact support?

**For demo/academic version:**
- This is a demonstration system
- Contact your instructor or project supervisor

**For production version:**
- Email: support@scholarmate.app
- In-app: Settings → Help & Support
- Response time: 24-48 hours

### What information should I provide when contacting support?

When reporting payment issues, include:
- 🆔 Transaction ID (if available)
- 📅 Date and time of payment attempt
- 💳 Payment method used
- 📱 Device and app version
- 📸 Screenshots (if applicable)
- 📝 Description of the issue

---

## 🔮 Future Features

### What features are planned?

Potential future enhancements:
- 🔄 Auto-renewal option
- 📧 Email receipts
- 💳 More payment methods (Nagad, Rocket, etc.)
- 🎁 Promotional codes and discounts
- 👥 Family/team subscriptions
- 📊 Usage analytics

### Will prices change?

**For demo system:** Prices are fixed for demonstration purposes.

**For production system:** 
- Current subscribers maintain their pricing
- New pricing would only apply to new subscriptions
- Advance notice would be provided for any changes

---

## 📚 Additional Resources

- **Payment Guide:** See `SUBSCRIPTION_PAYMENT_GUIDE.md` for step-by-step instructions
- **Troubleshooting:** See `SUBSCRIPTION_TROUBLESHOOTING.md` for detailed solutions
- **Technical Docs:** See `.kiro/specs/payment-subscription-system/` for developer documentation

---

## ⚠️ Important Disclaimer

**This is a demonstration/mock payment system for academic purposes.**

- No real money is processed
- Test credentials are used for validation
- Not suitable for production use without replacing with real payment gateways
- Designed to showcase payment flow and subscription management architecture

For production deployment, this system must be integrated with certified payment gateways like:
- SSLCommerz (Bangladesh)
- bKash Official API (Bangladesh)
- Stripe (International)
- PayPal (International)

---

**Last Updated:** November 2025  
**Version:** 1.0 (Demo)
