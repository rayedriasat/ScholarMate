# Design Document

## Overview

The Payment and Subscription System is a mock payment processing infrastructure designed for academic demonstration of ScholarMate's premium subscription model. The system simulates real payment gateway behavior for bKash, Debit Card, and Credit Card payment methods while maintaining a clean abstraction layer that allows future replacement with production payment gateways (SSLCommerz, bKash Official API) without modifying core application logic.

The system follows a three-tier architecture:
1. **Frontend Payment UI** - Flutter-based payment forms and result pages
2. **Backend Payment Gateway** - FastAPI endpoints with payment gateway abstraction
3. **Subscription Manager** - Database-backed subscription state management

Key design principles:
- **Abstraction-first**: Payment Gateway Interface enables seamless gateway replacement
- **Mock validation**: Hardcoded test credentials for demonstration purposes
- **Immediate activation**: Successful payments instantly grant Premium status
- **Audit trail**: Complete transaction logging for debugging and compliance
- **UI placement**: Subscription management strictly within Settings, not as main navigation

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                      Frontend (Flutter)                      │
├─────────────────────────────────────────────────────────────┤
│  Settings Screen                                             │
│  ├── Subscription Section                                    │
│  │   ├── Current Plan Display (Free/Premium)                │
│  │   ├── Upgrade Button                                      │
│  │   ├── Payment History                                     │
│  │   └── Renewal Status                                      │
│  │                                                            │
│  Payment Flow Screens                                        │
│  ├── Payment Method Selection                                │
│  ├── Payment Form (bKash/Card)                               │
│  ├── Payment Success Page                                    │
│  └── Payment Failed Page                                     │
└─────────────────────────────────────────────────────────────┘
                            ↓ HTTP
┌─────────────────────────────────────────────────────────────┐
│                    Backend (FastAPI)                         │
├─────────────────────────────────────────────────────────────┤
│  Payment Router (/api/payments)                              │
│  ├── POST /initialize                                        │
│  ├── POST /verify                                            │
│  └── GET /history                                            │
│                                                               │
│  Payment Gateway Interface (Abstract)                        │
│  ├── initialize_payment()                                    │
│  ├── verify_payment()                                        │
│  └── get_transaction_status()                                │
│                                                               │
│  Mock Payment Gateway (Implementation)                       │
│  ├── Validates test credentials                              │
│  ├── Generates transaction IDs                               │
│  └── Returns success/failure                                 │
│                                                               │
│  [Future] Real Payment Gateways                              │
│  ├── SSLCommerz Gateway                                      │
│  └── bKash Official Gateway                                  │
│                                                               │
│  Subscription Service                                        │
│  ├── activate_premium()                                      │
│  ├── get_subscription_status()                               │
│  └── record_transaction()                                    │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  Database (Supabase/PostgreSQL)              │
├─────────────────────────────────────────────────────────────┤
│  users table                                                 │
│  ├── subscription_status (free/premium)                      │
│  ├── subscription_activated_at                               │
│  └── subscription_expires_at                                 │
│                                                               │
│  transactions table                                          │
│  ├── transaction_id (unique)                                 │
│  ├── user_id                                                 │
│  ├── payment_method                                          │
│  ├── amount                                                  │
│  ├── status (success/failed)                                 │
│  ├── created_at                                              │
│  └── metadata (JSON)                                         │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

**Payment Initialization Flow:**
1. User clicks "Upgrade" in Settings → Subscription
2. Frontend navigates to Payment Method Selection screen
3. User selects payment method (bKash/Card) and enters details
4. Frontend calls `POST /api/payments/initialize` with payment data
5. Backend validates request and calls Payment Gateway Interface
6. Mock Gateway generates transaction ID and returns initialization response
7. Frontend displays loading state

**Payment Verification Flow:**
1. Frontend calls `POST /api/payments/verify` with transaction ID
2. Backend calls Payment Gateway Interface verify method
3. Mock Gateway validates credentials against test rules
4. If successful:
   - Subscription Service activates premium status
   - Transaction record created with status=success
   - Response includes transaction details
5. If failed:
   - Transaction record created with status=failed
   - Response includes error message
6. Frontend navigates to success/failure page based on response

**Subscription Status Check Flow:**
1. App initialization or Settings screen load
2. Frontend calls `GET /api/payments/subscription-status`
3. Backend queries users table for subscription_status
4. Response includes plan type, activation date, expiry date
5. Frontend updates UI to reflect Premium/Free status

## Components and Interfaces

### Frontend Components

#### 1. SubscriptionSection Widget
**Location:** `frontend/lib/widgets/subscription_section.dart`

**Responsibilities:**
- Display current subscription plan (Free/Premium)
- Show upgrade button for Free users
- Display renewal status for Premium users
- Show payment history list
- Provide retry option for failed payments

**State Management:**
- Uses `SubscriptionService` provider
- Listens to subscription status changes
- Refreshes on screen focus

**Key Methods:**
```dart
class SubscriptionSection extends StatefulWidget {
  Future<void> _loadSubscriptionStatus();
  Future<void> _loadPaymentHistory();
  void _navigateToPayment();
  void _retryPayment(String transactionId);
}
```

#### 2. PaymentMethodScreen
**Location:** `frontend/lib/screens/payment_method_screen.dart`

**Responsibilities:**
- Display payment method selection (bKash, Debit Card, Credit Card)
- Navigate to appropriate payment form based on selection

**UI Elements:**
- Three large selection cards with icons
- Clear visual distinction between methods
- Consistent with app theme

#### 3. PaymentFormScreen
**Location:** `frontend/lib/screens/payment_form_screen.dart`

**Responsibilities:**
- Display payment-method-specific input fields
- Validate input format (phone number, card number, CVV, expiry)
- Handle "Pay Now" button press
- Show loading indicator during processing
- Navigate to result page

**Input Validation:**
- bKash: Mobile number must match `01[0-9]{9}` pattern
- Card: Luhn algorithm validation for card number
- CVV: 3-digit numeric validation
- Expiry: Future date validation

**Key Methods:**
```dart
class PaymentFormScreen extends StatefulWidget {
  Future<void> _submitPayment();
  bool _validateBkashInput();
  bool _validateCardInput();
  void _showValidationError(String message);
}
```

#### 4. PaymentSuccessScreen
**Location:** `frontend/lib/screens/payment_success_screen.dart`

**Responsibilities:**
- Display success message with transaction ID
- Show paid amount
- Display "Premium Subscription Activated" banner
- Provide navigation back to Settings

#### 5. PaymentFailedScreen
**Location:** `frontend/lib/screens/payment_failed_screen.dart`

**Responsibilities:**
- Display error message
- Show transaction ID (if available)
- Provide "Retry Payment" button
- Provide navigation back to Settings

### Backend Components

#### 1. Payment Router
**Location:** `backend/app/routers/payments.py`

**Endpoints:**

```python
@router.post("/api/payments/initialize")
async def initialize_payment(request: PaymentInitRequest) -> PaymentInitResponse:
    """
    Initialize a payment transaction
    
    Args:
        request: Payment details (method, amount, user_id)
    
    Returns:
        transaction_id, payment_url (for mock, returns None)
    """

@router.post("/api/payments/verify")
async def verify_payment(request: PaymentVerifyRequest) -> PaymentVerifyResponse:
    """
    Verify payment and activate subscription
    
    Args:
        request: Transaction ID and payment credentials
    
    Returns:
        status (success/failed), transaction details
    """

@router.get("/api/payments/subscription-status")
async def get_subscription_status(user_id: str) -> SubscriptionStatusResponse:
    """
    Get current subscription status for user
    
    Args:
        user_id: Google sub claim
    
    Returns:
        plan, activated_at, expires_at
    """

@router.get("/api/payments/history")
async def get_payment_history(user_id: str) -> PaymentHistoryResponse:
    """
    Get payment transaction history
    
    Args:
        user_id: Google sub claim
    
    Returns:
        List of transactions with details
    """
```

#### 2. Payment Gateway Interface
**Location:** `backend/app/services/payment_gateway_interface.py`

**Abstract Base Class:**

```python
from abc import ABC, abstractmethod
from typing import Dict, Any

class PaymentGatewayInterface(ABC):
    """
    Abstract interface for payment gateway implementations.
    
    This interface allows seamless switching between mock and real
    payment gateways without changing application logic.
    """
    
    @abstractmethod
    async def initialize_payment(
        self,
        amount: float,
        currency: str,
        payment_method: str,
        user_id: str,
        metadata: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Initialize a payment transaction
        
        Returns:
            {
                "transaction_id": str,
                "payment_url": str | None,
                "status": str
            }
        """
        pass
    
    @abstractmethod
    async def verify_payment(
        self,
        transaction_id: str,
        payment_credentials: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Verify payment completion
        
        Returns:
            {
                "success": bool,
                "transaction_id": str,
                "amount": float,
                "message": str
            }
        """
        pass
    
    @abstractmethod
    async def get_transaction_status(
        self,
        transaction_id: str
    ) -> Dict[str, Any]:
        """
        Get current status of a transaction
        
        Returns:
            {
                "transaction_id": str,
                "status": str,
                "amount": float,
                "created_at": str
            }
        """
        pass
```

#### 3. Mock Payment Gateway
**Location:** `backend/app/services/mock_payment_gateway.py`

**Implementation:**

```python
from .payment_gateway_interface import PaymentGatewayInterface
import uuid
from datetime import datetime

class MockPaymentGateway(PaymentGatewayInterface):
    """
    Mock payment gateway for demonstration purposes.
    
    ⚠️ FOR ACADEMIC DEMONSTRATION ONLY ⚠️
    This implementation uses hardcoded test credentials and should
    NEVER be used in production.
    
    Test Credentials:
    - bKash: Mobile=01XXXXXXXXX, PIN=12345
    - Card: Number=4111111111111111, CVV=123, Expiry=any future date
    """
    
    # Mock test credentials
    BKASH_TEST_PIN = "12345"
    CARD_TEST_NUMBER = "4111111111111111"
    CARD_TEST_CVV = "123"
    
    def __init__(self):
        self.transactions = {}  # In-memory transaction storage
    
    async def initialize_payment(
        self,
        amount: float,
        currency: str,
        payment_method: str,
        user_id: str,
        metadata: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Initialize mock payment"""
        transaction_id = f"TXN_{uuid.uuid4().hex[:12].upper()}"
        
        self.transactions[transaction_id] = {
            "transaction_id": transaction_id,
            "amount": amount,
            "currency": currency,
            "payment_method": payment_method,
            "user_id": user_id,
            "status": "pending",
            "created_at": datetime.utcnow().isoformat(),
            "metadata": metadata
        }
        
        return {
            "transaction_id": transaction_id,
            "payment_url": None,  # Mock doesn't redirect
            "status": "pending"
        }
    
    async def verify_payment(
        self,
        transaction_id: str,
        payment_credentials: Dict[str, Any]
    ) -> Dict[str, Any]:
        """Verify mock payment using test credentials"""
        
        if transaction_id not in self.transactions:
            return {
                "success": False,
                "transaction_id": transaction_id,
                "amount": 0,
                "message": "Transaction not found"
            }
        
        transaction = self.transactions[transaction_id]
        payment_method = transaction["payment_method"]
        
        # Validate based on payment method
        success = False
        message = ""
        
        if payment_method == "bkash":
            mobile = payment_credentials.get("mobile_number", "")
            pin = payment_credentials.get("pin", "")
            
            # Check test credentials
            if mobile.startswith("01") and len(mobile) == 11 and pin == self.BKASH_TEST_PIN:
                success = True
                message = "Payment successful"
            else:
                message = "Invalid bKash credentials"
        
        elif payment_method in ["debit_card", "credit_card"]:
            card_number = payment_credentials.get("card_number", "").replace(" ", "")
            cvv = payment_credentials.get("cvv", "")
            expiry = payment_credentials.get("expiry", "")
            
            # Check test credentials
            if card_number == self.CARD_TEST_NUMBER and cvv == self.CARD_TEST_CVV:
                # Validate expiry is future date
                try:
                    month, year = expiry.split("/")
                    expiry_date = datetime(int(f"20{year}"), int(month), 1)
                    if expiry_date > datetime.now():
                        success = True
                        message = "Payment successful"
                    else:
                        message = "Card expired"
                except:
                    message = "Invalid expiry date format"
            else:
                message = "Invalid card credentials"
        
        # Update transaction status
        transaction["status"] = "success" if success else "failed"
        transaction["verified_at"] = datetime.utcnow().isoformat()
        
        return {
            "success": success,
            "transaction_id": transaction_id,
            "amount": transaction["amount"],
            "message": message
        }
    
    async def get_transaction_status(
        self,
        transaction_id: str
    ) -> Dict[str, Any]:
        """Get mock transaction status"""
        
        if transaction_id not in self.transactions:
            return {
                "transaction_id": transaction_id,
                "status": "not_found",
                "amount": 0,
                "created_at": None
            }
        
        transaction = self.transactions[transaction_id]
        return {
            "transaction_id": transaction_id,
            "status": transaction["status"],
            "amount": transaction["amount"],
            "created_at": transaction["created_at"]
        }
```

**TODO - Future Gateway Implementations:**
```python
# backend/app/services/sslcommerz_gateway.py
class SSLCommerzGateway(PaymentGatewayInterface):
    """
    Real SSLCommerz payment gateway implementation.
    
    TODO: Implement when production credentials are available.
    Configuration required:
    - SSLCOMMERZ_STORE_ID
    - SSLCOMMERZ_STORE_PASSWORD
    - SSLCOMMERZ_API_URL
    """
    pass

# backend/app/services/bkash_gateway.py
class BkashOfficialGateway(PaymentGatewayInterface):
    """
    Real bKash Official API implementation.
    
    TODO: Implement when production credentials are available.
    Configuration required:
    - BKASH_APP_KEY
    - BKASH_APP_SECRET
    - BKASH_USERNAME
    - BKASH_PASSWORD
    - BKASH_API_URL
    """
    pass
```

#### 4. Subscription Service
**Location:** `backend/app/services/subscription_service.py`

**Responsibilities:**
- Activate premium subscription after successful payment
- Query subscription status
- Record transaction history
- Handle subscription expiry (for future recurring billing)

**Key Methods:**

```python
class SubscriptionService:
    def __init__(self, supabase_client):
        self.supabase = supabase_client
    
    async def activate_premium(
        self,
        user_id: str,
        transaction_id: str,
        duration_days: int = 365
    ) -> Dict[str, Any]:
        """
        Activate premium subscription for user
        
        Args:
            user_id: Database user ID (UUID)
            transaction_id: Payment transaction ID
            duration_days: Subscription duration (default 1 year)
        
        Returns:
            Updated subscription details
        """
    
    async def get_subscription_status(
        self,
        user_id: str
    ) -> Dict[str, Any]:
        """
        Get current subscription status
        
        Returns:
            {
                "plan": "free" | "premium",
                "activated_at": str | None,
                "expires_at": str | None,
                "is_active": bool
            }
        """
    
    async def record_transaction(
        self,
        user_id: str,
        transaction_id: str,
        payment_method: str,
        amount: float,
        status: str,
        metadata: Dict[str, Any]
    ) -> None:
        """Record transaction in database"""
    
    async def get_payment_history(
        self,
        user_id: str,
        limit: int = 50
    ) -> List[Dict[str, Any]]:
        """Get user's payment history"""
```

### Frontend Services

#### SubscriptionService
**Location:** `frontend/lib/services/subscription_service.dart`

**Responsibilities:**
- Manage subscription state in frontend
- Call backend payment APIs
- Cache subscription status locally
- Notify listeners of status changes

**Key Methods:**

```dart
class SubscriptionService extends ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;
  
  SubscriptionStatus? _currentStatus;
  List<Transaction> _paymentHistory = [];
  bool _isLoading = false;
  
  Future<void> loadSubscriptionStatus();
  Future<void> loadPaymentHistory();
  
  Future<PaymentInitResponse> initializePayment({
    required String paymentMethod,
    required double amount,
  });
  
  Future<PaymentVerifyResponse> verifyPayment({
    required String transactionId,
    required Map<String, dynamic> credentials,
  });
  
  Future<void> retryFailedPayment(String transactionId);
  
  bool get isPremium => _currentStatus?.plan == 'premium';
  bool get isFree => _currentStatus?.plan == 'free';
}
```

## Data Models

### Database Schema

#### Users Table Extension
```sql
-- Add subscription fields to existing users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(20) DEFAULT 'free';
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_activated_at TIMESTAMP WITH TIME ZONE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMP WITH TIME ZONE;

-- Add index for subscription queries
CREATE INDEX IF NOT EXISTS idx_users_subscription_status ON users(subscription_status);

-- Add check constraint
ALTER TABLE users ADD CONSTRAINT check_subscription_status 
    CHECK (subscription_status IN ('free', 'premium'));
```

#### Transactions Table
```sql
-- Create transactions table for payment history
CREATE TABLE IF NOT EXISTS transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id VARCHAR(50) UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    payment_method VARCHAR(20) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'BDT',
    status VARCHAR(20) NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    verified_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT check_payment_method 
        CHECK (payment_method IN ('bkash', 'debit_card', 'credit_card')),
    CONSTRAINT check_status 
        CHECK (status IN ('pending', 'success', 'failed'))
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_transaction_id ON transactions(transaction_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC);

-- Enable RLS
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Add comments
COMMENT ON TABLE transactions IS 'Payment transaction history for subscription management';
COMMENT ON COLUMN transactions.transaction_id IS 'Unique transaction identifier from payment gateway';
COMMENT ON COLUMN transactions.metadata IS 'Additional payment details (JSON)';
```

### Pydantic Models

#### Request Models
```python
# backend/app/models/payments.py

from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime

class PaymentInitRequest(BaseModel):
    user_id: str = Field(..., description="Google sub claim")
    payment_method: str = Field(..., description="bkash, debit_card, or credit_card")
    amount: float = Field(..., gt=0, description="Payment amount")
    currency: str = Field(default="BDT", description="Currency code")

class PaymentVerifyRequest(BaseModel):
    transaction_id: str = Field(..., description="Transaction ID from initialization")
    payment_credentials: Dict[str, Any] = Field(..., description="Payment method specific credentials")
    # For bKash: {"mobile_number": str, "pin": str}
    # For Card: {"card_number": str, "cvv": str, "expiry": str}

class PaymentInitResponse(BaseModel):
    success: bool
    transaction_id: str
    payment_url: Optional[str] = None
    message: str

class PaymentVerifyResponse(BaseModel):
    success: bool
    transaction_id: str
    amount: float
    message: str
    subscription_status: Optional[str] = None

class SubscriptionStatusResponse(BaseModel):
    plan: str  # "free" or "premium"
    activated_at: Optional[datetime] = None
    expires_at: Optional[datetime] = None
    is_active: bool

class TransactionDetail(BaseModel):
    transaction_id: str
    payment_method: str
    amount: float
    currency: str
    status: str
    created_at: datetime
    verified_at: Optional[datetime] = None

class PaymentHistoryResponse(BaseModel):
    transactions: list[TransactionDetail]
    total_count: int
```

### Dart Models

```dart
// frontend/lib/models/subscription_status.dart

class SubscriptionStatus {
  final String plan; // 'free' or 'premium'
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final bool isActive;
  
  SubscriptionStatus({
    required this.plan,
    this.activatedAt,
    this.expiresAt,
    required this.isActive,
  });
  
  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      plan: json['plan'] as String,
      activatedAt: json['activated_at'] != null 
          ? DateTime.parse(json['activated_at']) 
          : null,
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at']) 
          : null,
      isActive: json['is_active'] as bool,
    );
  }
  
  bool get isPremium => plan == 'premium' && isActive;
  bool get isFree => plan == 'free' || !isActive;
}

// frontend/lib/models/transaction.dart

class Transaction {
  final String transactionId;
  final String paymentMethod;
  final double amount;
  final String currency;
  final String status;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  
  Transaction({
    required this.transactionId,
    required this.paymentMethod,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.verifiedAt,
  });
  
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      transactionId: json['transaction_id'] as String,
      paymentMethod: json['payment_method'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at']),
      verifiedAt: json['verified_at'] != null 
          ? DateTime.parse(json['verified_at']) 
          : null,
    );
  }
  
  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
  bool get isPending => status == 'pending';
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Transaction ID Uniqueness
*For any* set of payment transactions, all generated transaction IDs should be unique across the entire system.
**Validates: Requirements 3.4, 8.3**

### Property 2: Mock Validation Rules
*For any* payment submission, if the credentials match the test success criteria (bKash: mobile starting with "01" with 11 digits and PIN "12345", OR Card: number "4111111111111111", CVV "123", and future expiry date), then the payment should be marked as successful; otherwise, it should be marked as failed.
**Validates: Requirements 3.1, 3.2, 3.3**

### Property 3: Payment Response Completeness
*For any* payment validation, the response should include both the validation result (success/failed) and the transaction ID.
**Validates: Requirements 3.5**

### Property 4: Navigation Based on Payment Result
*For any* completed payment attempt, if the payment succeeds, the system should navigate to the success page; if the payment fails, the system should navigate to the failure page.
**Validates: Requirements 4.1, 4.3**

### Property 5: Success Page Information Completeness
*For any* payment success page display, the page should contain the transaction ID, the paid amount, and a premium activation message.
**Validates: Requirements 4.2**

### Property 6: Premium Activation on Success
*For any* successful payment, the user's subscription status should immediately be updated to "premium" in the system.
**Validates: Requirements 4.5, 5.1**

### Property 7: Subscription Persistence
*For any* subscription status change, querying the database after the change should return the updated subscription status.
**Validates: Requirements 5.2, 6.3**

### Property 8: Activation Timestamp Recording
*For any* subscription activation, the activated_at timestamp should be set to a non-null value representing the current time.
**Validates: Requirements 5.4**

### Property 9: Transaction History Completeness
*For any* transaction in the payment history, the displayed information should include transaction ID, amount, date, and status.
**Validates: Requirements 6.2, 8.4**

### Property 10: Transaction Status Display
*For any* transaction displayed in the history, the status should clearly indicate whether it was "success", "failed", or "pending".
**Validates: Requirements 6.4**

### Property 11: Retry Option for Failed Payments
*For any* user with at least one failed transaction, the payment history UI should provide a retry option for those failed transactions.
**Validates: Requirements 6.5**

### Property 12: Payment Logging Completeness
*For any* payment attempt, the system logs should contain entries for: (1) payment initiation with timestamp and user ID, (2) validation result, and (3) failure reason if payment failed.
**Validates: Requirements 8.1, 8.2, 8.5**

### Property 13: Input Validation Behavior
*For any* payment form input, if the input is invalid according to the payment method rules (bKash: mobile format, Card: card number format, CVV format, expiry format), the system should reject the input and display an error message.
**Validates: Requirements 9.2, 9.3**

### Property 14: Loading State During Processing
*For any* payment processing operation, while the operation is in progress, the UI should display a loading indicator.
**Validates: Requirements 9.4**

### Property 15: Subscription Status Display
*For any* subscription status (free or premium), the Settings Subscription section should display text indicating the current plan type.
**Validates: Requirements 1.2**

### Property 16: Conditional UI Rendering for Free Users
*For any* user with subscription status "free", the Subscription section should display an Upgrade button.
**Validates: Requirements 1.3**

### Property 17: Conditional UI Rendering for Premium Users
*For any* user with subscription status "premium", the Subscription section should display renewal status information.
**Validates: Requirements 1.4**

### Property 18: Payment Method Conditional Fields
*For any* payment method selection, if bKash is selected, the form should display Mobile Number and PIN fields; if Debit Card or Credit Card is selected, the form should display Card Number, Expiry Date, and CVV fields.
**Validates: Requirements 2.3, 2.4**

### Property 19: Upgrade Navigation
*For any* user clicking the Upgrade button, the system should navigate to the payment method selection page.
**Validates: Requirements 2.1**

## Error Handling

### Payment Processing Errors

**Network Failures:**
- Frontend should retry payment verification up to 3 times with exponential backoff
- Display user-friendly error message: "Connection issue. Please check your internet and try again."
- Store payment attempt locally for manual retry

**Invalid Credentials:**
- Display specific validation errors for each field
- bKash: "Invalid mobile number format" or "Incorrect PIN"
- Card: "Invalid card number", "Invalid CVV", or "Card expired"
- Do not expose mock validation rules to users

**Transaction Not Found:**
- If transaction ID is not found during verification, display: "Transaction not found. Please try again."
- Log error with transaction ID for debugging

**Database Errors:**
- If subscription activation fails, mark transaction as "pending_activation"
- Implement background job to retry activation
- Display: "Payment successful, but activation is pending. Please contact support if issue persists."

**Duplicate Transaction:**
- Check for existing transaction ID before creating new record
- If duplicate found, return existing transaction status
- Prevent double-charging

### Subscription Status Errors

**Expired Subscription:**
- Check expiry date on every app launch
- If expired, downgrade to free tier automatically
- Display notification: "Your premium subscription has expired. Upgrade to continue enjoying premium features."

**Status Sync Failures:**
- If frontend and backend subscription status mismatch, backend is source of truth
- Frontend should refresh status from backend on Settings screen load
- Cache status locally with TTL of 5 minutes

### UI Error States

**Form Validation:**
- Display inline error messages below each invalid field
- Disable "Pay Now" button until all fields are valid
- Use red color for error text, consistent with app theme

**Loading Timeouts:**
- If payment verification takes longer than 30 seconds, display: "Payment is taking longer than expected. Please wait..."
- After 60 seconds, allow user to cancel and retry

**Empty Payment History:**
- Display friendly message: "No payment history yet. Upgrade to premium to get started!"
- Show upgrade button

## Testing Strategy

### Unit Testing

**Backend Unit Tests:**

1. **Payment Gateway Interface Tests**
   - Test that MockPaymentGateway implements all interface methods
   - Test transaction ID generation produces unique values
   - Test mock validation rules for all payment methods
   - Test error handling for invalid inputs

2. **Subscription Service Tests**
   - Test premium activation updates database correctly
   - Test subscription status queries return correct data
   - Test transaction recording stores all required fields
   - Test payment history retrieval with pagination

3. **Payment Router Tests**
   - Test initialize endpoint creates transaction record
   - Test verify endpoint calls gateway and activates subscription
   - Test subscription-status endpoint returns correct format
   - Test history endpoint filters by user ID

**Frontend Unit Tests:**

1. **SubscriptionService Tests**
   - Test API call methods handle responses correctly
   - Test state updates notify listeners
   - Test error handling for network failures
   - Test local caching of subscription status

2. **Payment Form Validation Tests**
   - Test bKash mobile number format validation
   - Test card number Luhn algorithm validation
   - Test CVV format validation (3 digits)
   - Test expiry date future validation

3. **Widget Tests**
   - Test SubscriptionSection displays correct UI for free users
   - Test SubscriptionSection displays correct UI for premium users
   - Test PaymentFormScreen shows correct fields based on method
   - Test PaymentSuccessScreen displays transaction details
   - Test PaymentFailedScreen shows retry button

### Property-Based Testing

Property-based tests will use:
- **Python**: `hypothesis` library (backend)
- **Dart**: `test` package with custom generators (frontend)

Each property-based test should run a minimum of 100 iterations to ensure comprehensive coverage.

**Backend Property Tests:**

1. **Property 1: Transaction ID Uniqueness**
   - Generate 1000 payment initializations
   - Verify all transaction IDs are unique
   - **Feature: payment-subscription-system, Property 1: Transaction ID Uniqueness**

2. **Property 2: Mock Validation Rules**
   - Generate random payment credentials (valid and invalid)
   - Verify validation results match expected rules
   - **Feature: payment-subscription-system, Property 2: Mock Validation Rules**

3. **Property 6: Premium Activation on Success**
   - Generate random successful payments
   - Verify subscription status becomes "premium" for all
   - **Feature: payment-subscription-system, Property 6: Premium Activation on Success**

4. **Property 7: Subscription Persistence**
   - Generate random subscription updates
   - Verify database queries return updated values
   - **Feature: payment-subscription-system, Property 7: Subscription Persistence**

5. **Property 9: Transaction History Completeness**
   - Generate random transactions
   - Verify all records contain required fields
   - **Feature: payment-subscription-system, Property 9: Transaction History Completeness**

6. **Property 12: Payment Logging Completeness**
   - Generate random payment attempts
   - Verify logs contain all required entries
   - **Feature: payment-subscription-system, Property 12: Payment Logging Completeness**

**Frontend Property Tests:**

1. **Property 13: Input Validation Behavior**
   - Generate random valid and invalid inputs
   - Verify validation accepts valid and rejects invalid
   - **Feature: payment-subscription-system, Property 13: Input Validation Behavior**

2. **Property 15: Subscription Status Display**
   - Generate random subscription statuses
   - Verify UI displays correct plan type
   - **Feature: payment-subscription-system, Property 15: Subscription Status Display**

3. **Property 18: Payment Method Conditional Fields**
   - Generate random payment method selections
   - Verify correct fields are displayed
   - **Feature: payment-subscription-system, Property 18: Payment Method Conditional Fields**

### Integration Testing

**End-to-End Payment Flow:**
1. Start with free user
2. Navigate to Settings → Subscription
3. Click Upgrade button
4. Select payment method
5. Enter test credentials
6. Submit payment
7. Verify navigation to success page
8. Verify subscription status updated to premium
9. Verify transaction appears in payment history

**Failed Payment Flow:**
1. Start with free user
2. Navigate to payment form
3. Enter invalid credentials
4. Submit payment
5. Verify navigation to failure page
6. Verify subscription status remains free
7. Verify failed transaction in history
8. Click retry button
9. Verify navigation back to payment form

**Payment History Flow:**
1. Create multiple transactions (success and failed)
2. Navigate to Settings → Subscription
3. Verify all transactions displayed
4. Verify transaction details are correct
5. Verify retry button only on failed transactions

### Manual Testing Checklist

**UI/UX Testing:**
- [ ] Subscription section appears in Settings (not as main sidebar item)
- [ ] Optional upgrade button in sidebar/nav redirects to Settings
- [ ] Payment forms are visually consistent with app theme
- [ ] Loading indicators appear during processing
- [ ] Error messages are clear and actionable
- [ ] Success page displays all required information
- [ ] Payment history is readable and well-formatted

**Cross-Platform Testing:**
- [ ] Test on Android device
- [ ] Test on iOS device (if available)
- [ ] Test on Web browser
- [ ] Test on Windows desktop
- [ ] Verify responsive layout on different screen sizes

**Edge Cases:**
- [ ] Test with very long transaction IDs
- [ ] Test with special characters in names
- [ ] Test rapid clicking of Pay Now button
- [ ] Test navigation back button during payment
- [ ] Test app restart during payment processing
- [ ] Test with poor network connection

## Configuration

### Environment Variables

**Backend (.env):**
```bash
# Payment Gateway Configuration
PAYMENT_GATEWAY_TYPE=mock  # Options: mock, sslcommerz, bkash
PAYMENT_CURRENCY=BDT

# Mock Gateway Settings (for demonstration only)
MOCK_BKASH_TEST_PIN=12345
MOCK_CARD_TEST_NUMBER=4111111111111111
MOCK_CARD_TEST_CVV=123

# TODO: Add when real gateways are integrated
# SSLCOMMERZ_STORE_ID=your_store_id
# SSLCOMMERZ_STORE_PASSWORD=your_store_password
# SSLCOMMERZ_API_URL=https://sandbox.sslcommerz.com
# BKASH_APP_KEY=your_app_key
# BKASH_APP_SECRET=your_app_secret
# BKASH_USERNAME=your_username
# BKASH_PASSWORD=your_password
# BKASH_API_URL=https://tokenized.sandbox.bka.sh
```

**Frontend (dart_defines.json):**
```json
{
  "PAYMENT_ENABLED": "true",
  "PREMIUM_PRICE": "999.00",
  "PREMIUM_CURRENCY": "BDT"
}
```

### Gateway Selection

The backend should use a factory pattern to select the appropriate payment gateway:

```python
# backend/app/services/payment_gateway_factory.py

from .payment_gateway_interface import PaymentGatewayInterface
from .mock_payment_gateway import MockPaymentGateway
# TODO: Import real gateways when implemented
# from .sslcommerz_gateway import SSLCommerzGateway
# from .bkash_gateway import BkashOfficialGateway
import os

def get_payment_gateway() -> PaymentGatewayInterface:
    """
    Factory function to get the configured payment gateway.
    
    Returns the appropriate gateway implementation based on
    PAYMENT_GATEWAY_TYPE environment variable.
    
    TODO: When real gateways are implemented, add cases for:
    - "sslcommerz" -> SSLCommerzGateway()
    - "bkash" -> BkashOfficialGateway()
    """
    gateway_type = os.getenv("PAYMENT_GATEWAY_TYPE", "mock")
    
    if gateway_type == "mock":
        return MockPaymentGateway()
    # TODO: Add real gateway cases
    # elif gateway_type == "sslcommerz":
    #     return SSLCommerzGateway(
    #         store_id=os.getenv("SSLCOMMERZ_STORE_ID"),
    #         store_password=os.getenv("SSLCOMMERZ_STORE_PASSWORD"),
    #         api_url=os.getenv("SSLCOMMERZ_API_URL")
    #     )
    # elif gateway_type == "bkash":
    #     return BkashOfficialGateway(
    #         app_key=os.getenv("BKASH_APP_KEY"),
    #         app_secret=os.getenv("BKASH_APP_SECRET"),
    #         username=os.getenv("BKASH_USERNAME"),
    #         password=os.getenv("BKASH_PASSWORD"),
    #         api_url=os.getenv("BKASH_API_URL")
    #     )
    else:
        raise ValueError(f"Unknown payment gateway type: {gateway_type}")
```

## Security Considerations

### Mock Gateway Warnings

1. **Hardcoded Credentials**: The mock gateway uses hardcoded test credentials. These MUST be clearly documented as test-only and MUST NOT be used in production.

2. **No Real Validation**: The mock gateway does not perform real payment processing. It only simulates the flow for demonstration purposes.

3. **In-Memory Storage**: The mock gateway stores transactions in memory, which will be lost on server restart. This is acceptable for demonstration but not for production.

### Future Production Requirements

When integrating real payment gateways:

1. **PCI Compliance**: Never store raw card numbers. Use tokenization provided by payment gateway.

2. **HTTPS Only**: All payment endpoints must use HTTPS in production.

3. **Rate Limiting**: Implement rate limiting on payment endpoints to prevent abuse.

4. **Webhook Verification**: Verify webhook signatures from payment gateways to prevent spoofing.

5. **Idempotency**: Implement idempotency keys to prevent duplicate charges.

6. **Audit Logging**: Log all payment attempts with sufficient detail for compliance and debugging.

7. **Data Retention**: Follow PCI DSS guidelines for payment data retention.

## Deployment Considerations

### Database Migration

Before deploying, run the migration to add subscription fields:

```bash
# Apply migration
psql $DATABASE_URL -f backend/supabase_migrations/006_subscription_system.sql
```

### Feature Flag

Consider using a feature flag to enable/disable the payment system:

```python
# backend/app/config.py
PAYMENT_SYSTEM_ENABLED = os.getenv("PAYMENT_SYSTEM_ENABLED", "false").lower() == "true"
```

This allows deploying the code without immediately exposing the feature to users.

### Monitoring

Monitor the following metrics:

1. **Payment Success Rate**: Percentage of successful vs failed payments
2. **Average Payment Time**: Time from initialization to verification
3. **Subscription Activation Rate**: Percentage of successful payments that activate premium
4. **Failed Payment Reasons**: Distribution of failure reasons for debugging

### Rollback Plan

If issues are discovered after deployment:

1. Set `PAYMENT_SYSTEM_ENABLED=false` to disable new payments
2. Existing premium subscriptions remain active
3. Fix issues and re-enable
4. No data loss as transactions are persisted

## Future Enhancements

### Recurring Billing

For future subscription renewals:

1. Store payment method tokens (provided by real gateways)
2. Implement scheduled job to charge before expiry
3. Send email notifications before renewal
4. Handle failed renewals with retry logic

### Multiple Subscription Tiers

Support different premium tiers:

1. Add `subscription_tier` field to users table
2. Define tier features in configuration
3. Update payment flow to select tier
4. Implement tier-based feature gating

### Refund Support

For customer service:

1. Add refund endpoint to payment router
2. Implement refund method in gateway interface
3. Update transaction status to "refunded"
4. Downgrade subscription on refund

### Payment Analytics Dashboard

For business insights:

1. Create admin dashboard showing payment metrics
2. Display revenue over time
3. Show conversion funnel (free → upgrade click → payment → success)
4. Track most popular payment methods

## Documentation Requirements

### User-Facing Documentation

1. **Subscription FAQ**: Explain what premium includes, pricing, payment methods
2. **Payment Guide**: Step-by-step instructions with screenshots
3. **Troubleshooting**: Common payment issues and solutions

### Developer Documentation

1. **Gateway Integration Guide**: How to add new payment gateway
2. **API Documentation**: OpenAPI/Swagger docs for payment endpoints
3. **Testing Guide**: How to test payment flow in development
4. **Configuration Guide**: Environment variables and their purposes

### Code Documentation

1. **Interface Documentation**: Docstrings explaining gateway interface contract
2. **Mock Gateway Comments**: Clear warnings about demonstration-only nature
3. **TODO Comments**: Mark all future gateway integration points
4. **Migration Comments**: Explain database schema changes
