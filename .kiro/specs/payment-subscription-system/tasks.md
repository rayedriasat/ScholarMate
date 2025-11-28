# Implementation Plan

- [x] 1. Set up database schema and migrations





  - Create migration file `006_subscription_system.sql`
  - Add subscription fields to users table (subscription_status, subscription_activated_at, subscription_expires_at)
  - Create transactions table with all required fields
  - Add indexes for performance
  - Enable RLS policies
  - _Requirements: 5.1, 5.2, 6.3, 8.4_

- [x] 2. Implement backend payment gateway abstraction layer




- [x] 2.1 Create Payment Gateway Interface


  - Define abstract base class with initialize_payment, verify_payment, and get_transaction_status methods
  - Add comprehensive docstrings explaining the interface contract
  - Include type hints for all parameters and return values
  - _Requirements: 7.1, 10.1_

- [x] 2.2 Implement Mock Payment Gateway


  - Create MockPaymentGateway class implementing PaymentGatewayInterface
  - Implement test credential validation (bKash: 01XXXXXXXXX + PIN 12345, Card: 4111111111111111 + CVV 123)
  - Generate unique transaction IDs using UUID
  - Store transactions in-memory for demo purposes
  - Add clear warning comments about demonstration-only nature
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 7.3, 10.2_

- [ ]* 2.3 Write property test for transaction ID uniqueness
  - **Property 1: Transaction ID Uniqueness**
  - **Validates: Requirements 3.4, 8.3**

- [ ]* 2.4 Write property test for mock validation rules
  - **Property 2: Mock Validation Rules**
  - **Validates: Requirements 3.1, 3.2, 3.3**

- [x] 2.5 Create payment gateway factory


  - Implement factory function to select gateway based on environment variable
  - Add TODO comments for future SSLCommerz and bKash gateway integration
  - _Requirements: 7.4, 10.3_

- [x] 3. Implement backend subscription service





- [x] 3.1 Create SubscriptionService class


  - Implement activate_premium method to update user subscription status
  - Implement get_subscription_status method to query current status
  - Implement record_transaction method to store payment records
  - Implement get_payment_history method with pagination
  - Add proper error handling for database operations
  - _Requirements: 5.1, 5.2, 5.4, 6.3, 8.4_

- [ ]* 3.2 Write property test for premium activation
  - **Property 6: Premium Activation on Success**
  - **Validates: Requirements 4.5, 5.1**

- [ ]* 3.3 Write property test for subscription persistence
  - **Property 7: Subscription Persistence**
  - **Validates: Requirements 5.2, 6.3**

- [ ]* 3.4 Write property test for transaction history completeness
  - **Property 9: Transaction History Completeness**
  - **Validates: Requirements 6.2, 8.4**

- [ ] 4. Implement backend payment router and endpoints
- [x] 4.1 Create Pydantic models for payment requests and responses





  - Define PaymentInitRequest, PaymentVerifyRequest, PaymentInitResponse, PaymentVerifyResponse
  - Define SubscriptionStatusResponse, TransactionDetail, PaymentHistoryResponse
  - Add validation rules and field descriptions
  - _Requirements: 3.5, 4.2, 6.2_

- [x] 4.2 Implement POST /api/payments/initialize endpoint





  - Accept payment method, amount, and user ID
  - Call payment gateway initialize_payment method
  - Return transaction ID and status
  - Add logging for payment initiation
  - _Requirements: 2.1, 8.1_

- [x] 4.3 Implement POST /api/payments/verify endpoint





  - Accept transaction ID and payment credentials
  - Call payment gateway verify_payment method
  - If successful, call subscription service to activate premium
  - Record transaction in database
  - Add logging for validation result
  - _Requirements: 3.1, 3.2, 3.3, 4.5, 5.1, 8.2_

- [x] 4.4 Implement GET /api/payments/subscription-status endpoint



  - Accept user ID parameter
  - Query subscription service for current status
  - Return plan type, activation date, and expiry date
  - _Requirements: 1.2, 5.1_

- [x] 4.5 Implement GET /api/payments/history endpoint





  - Accept user ID parameter
  - Query subscription service for payment history
  - Return list of transactions with all details
  - _Requirements: 6.2, 6.4_

- [ ]* 4.6 Write property test for payment logging completeness
  - **Property 12: Payment Logging Completeness**
  - **Validates: Requirements 8.1, 8.2, 8.5**

- [ ]* 4.7 Write unit tests for payment router endpoints
  - Test initialize endpoint creates transaction
  - Test verify endpoint activates subscription on success
  - Test subscription-status endpoint returns correct format
  - Test history endpoint filters by user ID
  - _Requirements: 2.1, 3.1, 4.5, 6.2_

- [x] 5. Checkpoint - Ensure backend tests pass





  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Implement frontend subscription service
- [ ] 6.1 Create SubscriptionService class with ChangeNotifier
  - Implement loadSubscriptionStatus method to fetch from backend
  - Implement loadPaymentHistory method to fetch transactions
  - Implement initializePayment method to call backend initialize endpoint
  - Implement verifyPayment method to call backend verify endpoint
  - Add state management with notifyListeners
  - Add local caching with 5-minute TTL
  - _Requirements: 1.2, 2.1, 3.1, 6.2_

- [ ]* 6.2 Write property test for subscription status display
  - **Property 15: Subscription Status Display**
  - **Validates: Requirements 1.2**

- [ ] 7. Implement frontend data models
- [ ] 7.1 Create SubscriptionStatus model
  - Add fields: plan, activatedAt, expiresAt, isActive
  - Implement fromJson factory constructor
  - Add computed properties: isPremium, isFree
  - _Requirements: 1.2, 5.1_

- [ ] 7.2 Create Transaction model
  - Add fields: transactionId, paymentMethod, amount, currency, status, createdAt, verifiedAt
  - Implement fromJson factory constructor
  - Add computed properties: isSuccess, isFailed, isPending
  - _Requirements: 6.2, 6.4_

- [ ] 8. Implement Settings Subscription section widget
- [ ] 8.1 Create SubscriptionSection widget
  - Display current plan status (Free/Premium)
  - Show Upgrade button for Free users
  - Show renewal status for Premium users
  - Display payment history list
  - Provide retry button for failed payments
  - Use SubscriptionService provider for state
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 6.1, 6.5_

- [ ]* 8.2 Write property test for conditional UI rendering
  - **Property 16: Conditional UI Rendering for Free Users**
  - **Property 17: Conditional UI Rendering for Premium Users**
  - **Validates: Requirements 1.3, 1.4**

- [ ]* 8.3 Write widget tests for SubscriptionSection
  - Test displays correct UI for free users
  - Test displays correct UI for premium users
  - Test payment history displays all transactions
  - Test retry button appears for failed payments
  - _Requirements: 1.1, 1.3, 1.4, 6.1, 6.5_

- [ ] 9. Integrate Subscription section into Settings screen
  - Add SubscriptionSection widget to Settings screen
  - Ensure proper placement (not as main sidebar item)
  - Add optional small Upgrade button to sidebar/nav that redirects to Settings
  - _Requirements: 1.1, 1.5_

- [ ] 10. Implement payment method selection screen
- [ ] 10.1 Create PaymentMethodScreen
  - Display three selection cards: bKash, Debit Card, Credit Card
  - Add icons and clear visual distinction
  - Navigate to PaymentFormScreen with selected method
  - Use consistent app theme styling
  - _Requirements: 2.2, 2.1_

- [ ]* 10.2 Write widget test for payment method screen
  - Test displays all three payment options
  - Test navigation on selection
  - _Requirements: 2.2_

- [ ] 11. Implement payment form screen
- [ ] 11.1 Create PaymentFormScreen with method-specific fields
  - For bKash: Mobile Number and PIN input fields
  - For Card: Card Number, Expiry Date, and CVV input fields
  - Add Amount field (pre-filled from config)
  - Add Pay Now button
  - Implement input validation (mobile format, card Luhn, CVV, expiry)
  - Show inline validation errors
  - Disable Pay Now until all fields valid
  - _Requirements: 2.3, 2.4, 2.5, 9.2, 9.3_

- [ ] 11.2 Implement payment submission logic
  - Call SubscriptionService.initializePayment on form submit
  - Show loading indicator during processing
  - Call SubscriptionService.verifyPayment with credentials
  - Navigate to success/failure page based on result
  - Handle network errors with retry logic
  - _Requirements: 3.1, 3.2, 3.3, 4.1, 4.3, 9.4_

- [ ]* 11.3 Write property test for input validation
  - **Property 13: Input Validation Behavior**
  - **Validates: Requirements 9.2, 9.3**

- [ ]* 11.4 Write property test for payment method conditional fields
  - **Property 18: Payment Method Conditional Fields**
  - **Validates: Requirements 2.3, 2.4**

- [ ]* 11.5 Write widget tests for payment form
  - Test bKash form shows correct fields
  - Test card form shows correct fields
  - Test validation rejects invalid inputs
  - Test Pay Now button disabled when invalid
  - Test loading indicator during submission
  - _Requirements: 2.3, 2.4, 9.2, 9.4_

- [ ] 12. Implement payment result screens
- [ ] 12.1 Create PaymentSuccessScreen
  - Display success message with transaction ID
  - Show paid amount
  - Display "Premium Subscription Activated" banner
  - Add navigation button back to Settings
  - _Requirements: 4.2_

- [ ] 12.2 Create PaymentFailedScreen
  - Display error message
  - Show transaction ID if available
  - Add Retry Payment button
  - Add navigation button back to Settings
  - _Requirements: 4.4_

- [ ]* 12.3 Write property test for navigation based on payment result
  - **Property 4: Navigation Based on Payment Result**
  - **Validates: Requirements 4.1, 4.3**

- [ ]* 12.4 Write widget tests for result screens
  - Test success screen displays all required info
  - Test failure screen shows retry option
  - Test navigation buttons work correctly
  - _Requirements: 4.2, 4.4_

- [ ] 13. Implement upgrade navigation flow
- [ ] 13.1 Wire up Upgrade button navigation
  - Connect Upgrade button in SubscriptionSection to PaymentMethodScreen
  - Ensure navigation preserves app state
  - _Requirements: 2.1, 19_

- [ ]* 13.2 Write property test for upgrade navigation
  - **Property 19: Upgrade Navigation**
  - **Validates: Requirements 2.1**

- [ ] 14. Add environment configuration
- [ ] 14.1 Update backend .env.template
  - Add PAYMENT_GATEWAY_TYPE, PAYMENT_CURRENCY
  - Add mock gateway test credentials
  - Add TODO comments for real gateway credentials
  - _Requirements: 10.5_

- [ ] 14.2 Update frontend dart_defines.json.template
  - Add PAYMENT_ENABLED, PREMIUM_PRICE, PREMIUM_CURRENCY
  - _Requirements: 10.5_

- [ ] 15. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 16. Integration testing and polish
- [ ]* 16.1 Perform end-to-end payment flow testing
  - Test complete flow from free user to premium activation
  - Test failed payment flow with retry
  - Test payment history display
  - _Requirements: All_

- [ ]* 16.2 Cross-platform testing
  - Test on Android
  - Test on Web
  - Test on Windows
  - Verify responsive layouts
  - _Requirements: 9.1, 9.5_

- [ ] 16.3 Add user-facing documentation
  - Create subscription FAQ
  - Create payment guide with instructions
  - Add troubleshooting section
  - _Requirements: 9.3_

- [ ] 17. Final checkpoint - Complete system verification
  - Ensure all tests pass, ask the user if questions arise.
