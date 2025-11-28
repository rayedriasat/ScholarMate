"""
Mock Payment Gateway Implementation

⚠️  FOR ACADEMIC DEMONSTRATION ONLY ⚠️

This module provides a mock payment gateway for demonstration and testing purposes.
It simulates payment processing behavior without connecting to real payment providers.

CRITICAL WARNINGS:
- This implementation uses HARDCODED test credentials
- NO real payment processing occurs
- Transactions are stored IN-MEMORY and lost on restart
- NEVER use this in production environments
- This is for ACADEMIC DEMONSTRATION ONLY

Test Credentials:
- bKash: Mobile number starting with "01" (11 digits) + PIN "12345"
- Card: Number "4111111111111111" + CVV "123" + Any future expiry date

When ready for production, replace this with real gateway implementations
(SSLCommerz, bKash Official API) that implement PaymentGatewayInterface.
"""

from .payment_gateway_interface import PaymentGatewayInterface
from typing import Dict, Any
from datetime import datetime, timezone
import uuid


class MockPaymentGateway(PaymentGatewayInterface):
    """
    Mock payment gateway for demonstration purposes.
    
    ⚠️  DEMONSTRATION ONLY - NOT FOR PRODUCTION USE ⚠️
    
    This class simulates payment gateway behavior for academic demonstration
    of the ScholarMate subscription system. It validates against hardcoded
    test credentials and stores transactions in memory.
    
    Test Credentials (for successful payments):
    - bKash:
        * Mobile Number: Must start with "01" and be exactly 11 digits
        * PIN: Must be "12345"
    - Debit/Credit Card:
        * Card Number: Must be "4111111111111111"
        * CVV: Must be "123"
        * Expiry: Must be a future date in MM/YY format
    
    Any credentials not matching these exact patterns will result in
    payment failure, simulating real gateway validation behavior.
    
    Attributes:
        BKASH_TEST_PIN: Hardcoded PIN for successful bKash payments
        CARD_TEST_NUMBER: Hardcoded card number for successful card payments
        CARD_TEST_CVV: Hardcoded CVV for successful card payments
        transactions: In-memory storage of transaction records
    """
    
    # Hardcoded test credentials for demonstration
    # ⚠️  These are NOT secure and should NEVER be used in production
    BKASH_TEST_PIN = "12345"
    CARD_TEST_NUMBER = "4111111111111111"
    CARD_TEST_CVV = "123"
    
    def __init__(self):
        """
        Initialize the mock payment gateway.
        
        Creates an empty in-memory transaction store. All transactions
        will be lost when the server restarts.
        """
        # In-memory transaction storage
        # ⚠️  Data is lost on server restart - acceptable for demo only
        self.transactions: Dict[str, Dict[str, Any]] = {}
    
    async def initialize_payment(
        self,
        amount: float,
        currency: str,
        payment_method: str,
        user_id: str,
        metadata: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Initialize a mock payment transaction.
        
        Generates a unique transaction ID and stores the transaction details
        in memory with "pending" status. No actual payment processing occurs.
        
        Args:
            amount: Payment amount (must be positive)
            currency: Currency code (e.g., "BDT")
            payment_method: "bkash", "debit_card", or "credit_card"
            user_id: User identifier
            metadata: Additional transaction context
        
        Returns:
            Dictionary with transaction_id, payment_url (None for mock),
            and status ("pending")
        
        Raises:
            ValueError: If amount is not positive or payment_method is invalid
        """
        # Validate inputs
        if amount <= 0:
            raise ValueError(f"Amount must be positive, got {amount}")
        
        valid_methods = ["bkash", "debit_card", "credit_card"]
        if payment_method not in valid_methods:
            raise ValueError(
                f"Invalid payment method '{payment_method}'. "
                f"Must be one of: {', '.join(valid_methods)}"
            )
        
        # Generate unique transaction ID
        # Format: TXN_<12 uppercase hex characters>
        transaction_id = f"TXN_{uuid.uuid4().hex[:12].upper()}"
        
        # Store transaction in memory
        self.transactions[transaction_id] = {
            "transaction_id": transaction_id,
            "amount": amount,
            "currency": currency,
            "payment_method": payment_method,
            "user_id": user_id,
            "status": "pending",
            "created_at": datetime.now(timezone.utc).isoformat(),
            "metadata": metadata,
            "verified_at": None
        }
        
        return {
            "transaction_id": transaction_id,
            "payment_url": None,  # Mock gateway doesn't redirect
            "status": "pending"
        }
    
    async def verify_payment(
        self,
        transaction_id: str,
        payment_credentials: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Verify a mock payment using test credentials.
        
        Validates the provided credentials against hardcoded test patterns.
        If credentials match the test success criteria, marks payment as
        successful. Otherwise, marks as failed.
        
        ⚠️  This is MOCK validation only - no real payment processing occurs
        
        Args:
            transaction_id: Transaction ID from initialize_payment
            payment_credentials: Payment method specific credentials
                For bKash: {"mobile_number": str, "pin": str}
                For Cards: {"card_number": str, "cvv": str, "expiry": str}
        
        Returns:
            Dictionary with success (bool), transaction_id, amount, and message
        
        Raises:
            ValueError: If transaction_id is not found
        """
        # Check if transaction exists
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
            # Validate bKash credentials
            mobile = payment_credentials.get("mobile_number", "")
            pin = payment_credentials.get("pin", "")
            
            # Debug logging
            print(f"DEBUG: bKash verification attempt")
            print(f"  Mobile: '{mobile}' (length: {len(mobile)})")
            print(f"  PIN: '{pin}'")
            print(f"  Expected PIN: '{self.BKASH_TEST_PIN}'")
            print(f"  Starts with 01: {mobile.startswith('01')}")
            print(f"  Is digit: {mobile.isdigit()}")
            print(f"  PIN match: {pin == self.BKASH_TEST_PIN}")
            
            # Test success criteria:
            # - Mobile number starts with "01"
            # - Mobile number is exactly 11 digits
            # - PIN is "12345"
            if (mobile.startswith("01") and 
                len(mobile) == 11 and 
                mobile.isdigit() and
                pin == self.BKASH_TEST_PIN):
                success = True
                message = "Payment successful"
            else:
                # Provide detailed error message
                if not mobile.startswith("01"):
                    message = "Mobile number must start with 01"
                elif len(mobile) != 11:
                    message = f"Mobile number must be 11 digits (got {len(mobile)})"
                elif not mobile.isdigit():
                    message = "Mobile number must contain only digits"
                elif pin != self.BKASH_TEST_PIN:
                    message = f"Invalid PIN (expected: {self.BKASH_TEST_PIN})"
                else:
                    message = "Invalid bKash credentials"
        
        elif payment_method in ["debit_card", "credit_card"]:
            # Validate card credentials
            card_number = payment_credentials.get("card_number", "").replace(" ", "")
            cvv = payment_credentials.get("cvv", "")
            expiry = payment_credentials.get("expiry", "")
            
            # Debug logging
            print(f"DEBUG: Card verification attempt")
            print(f"  Card Number: '{card_number}'")
            print(f"  CVV: '{cvv}'")
            print(f"  Expiry: '{expiry}'")
            
            # Test success criteria:
            # - Card number is "4111111111111111"
            # - CVV is "123"
            # - Expiry is a future date in MM/YY format
            if card_number == self.CARD_TEST_NUMBER and cvv == self.CARD_TEST_CVV:
                # Validate expiry is future date
                try:
                    # Parse MM/YY format
                    month_str, year_str = expiry.split("/")
                    month = int(month_str)
                    year = int(f"20{year_str}")  # Convert YY to 20YY
                    
                    # Create datetime for first day of expiry month
                    expiry_date = datetime(year, month, 1)
                    
                    # Check if expiry is in the future
                    if expiry_date > datetime.now():
                        success = True
                        message = "Payment successful"
                    else:
                        message = "Card expired"
                except (ValueError, IndexError):
                    message = "Invalid expiry date format (use MM/YY)"
            else:
                message = "Invalid card credentials"
        else:
            message = f"Unsupported payment method: {payment_method}"
        
        # Update transaction status
        transaction["status"] = "success" if success else "failed"
        transaction["verified_at"] = datetime.now(timezone.utc).isoformat()
        
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
        """
        Get the current status of a mock transaction.
        
        Retrieves transaction details from in-memory storage.
        
        Args:
            transaction_id: Transaction ID to query
        
        Returns:
            Dictionary with transaction_id, status, amount, and created_at
        """
        # Check if transaction exists
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
