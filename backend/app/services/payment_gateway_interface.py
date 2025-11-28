"""
Payment Gateway Interface

This module defines the abstract interface for payment gateway implementations.
The interface allows seamless switching between mock and real payment gateways
without changing application logic or frontend code.

All payment gateway implementations must conform to this interface to ensure
consistent behavior across different payment providers.
"""

from abc import ABC, abstractmethod
from typing import Dict, Any


class PaymentGatewayInterface(ABC):
    """
    Abstract interface for payment gateway implementations.
    
    This interface provides a standardized contract for payment processing,
    enabling the application to switch between different payment providers
    (mock, SSLCommerz, bKash Official API, etc.) without modifying core
    application logic.
    
    All implementing classes must provide concrete implementations of:
    - initialize_payment: Start a new payment transaction
    - verify_payment: Verify and complete a payment transaction
    - get_transaction_status: Query the current status of a transaction
    
    Design Principles:
    - Gateway-agnostic: Interface works with any payment provider
    - Async-first: All methods are async for non-blocking I/O
    - Type-safe: Comprehensive type hints for all parameters and returns
    - Error-transparent: Implementations should raise appropriate exceptions
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
        Initialize a new payment transaction.
        
        This method creates a new payment transaction and returns the necessary
        information for the client to proceed with payment. For redirect-based
        gateways, this includes a payment URL. For direct gateways, it returns
        a transaction ID for subsequent verification.
        
        Args:
            amount: Payment amount in the specified currency (must be positive)
            currency: ISO 4217 currency code (e.g., "BDT", "USD")
            payment_method: Payment method identifier
                           ("bkash", "debit_card", "credit_card")
            user_id: Unique identifier for the user making the payment
            metadata: Additional payment context (e.g., subscription details,
                     user email, order information)
        
        Returns:
            Dictionary containing:
                - transaction_id (str): Unique identifier for this transaction
                - payment_url (str | None): Redirect URL for payment (if applicable)
                - status (str): Initial transaction status (typically "pending")
                - Additional gateway-specific fields as needed
        
        Raises:
            ValueError: If amount is invalid or payment_method is unsupported
            ConnectionError: If gateway communication fails
            
        Example:
            >>> gateway = MockPaymentGateway()
            >>> result = await gateway.initialize_payment(
            ...     amount=999.00,
            ...     currency="BDT",
            ...     payment_method="bkash",
            ...     user_id="user_123",
            ...     metadata={"subscription_type": "premium"}
            ... )
            >>> print(result["transaction_id"])
            TXN_ABC123DEF456
        """
        pass
    
    @abstractmethod
    async def verify_payment(
        self,
        transaction_id: str,
        payment_credentials: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Verify and complete a payment transaction.
        
        This method validates the payment credentials and determines whether
        the payment was successful. For mock gateways, this validates against
        test credentials. For real gateways, this communicates with the payment
        provider's API to confirm payment completion.
        
        Args:
            transaction_id: Unique transaction identifier from initialize_payment
            payment_credentials: Payment method specific credentials
                For bKash:
                    - mobile_number (str): Mobile number (e.g., "01712345678")
                    - pin (str): Payment PIN
                For Cards:
                    - card_number (str): Card number
                    - cvv (str): Card verification value
                    - expiry (str): Expiry date in MM/YY format
        
        Returns:
            Dictionary containing:
                - success (bool): Whether payment was successful
                - transaction_id (str): Transaction identifier (echoed back)
                - amount (float): Payment amount
                - message (str): Human-readable result message
                - Additional gateway-specific fields (e.g., gateway_transaction_id)
        
        Raises:
            ValueError: If transaction_id is not found or credentials are malformed
            ConnectionError: If gateway communication fails
            
        Example:
            >>> result = await gateway.verify_payment(
            ...     transaction_id="TXN_ABC123DEF456",
            ...     payment_credentials={
            ...         "mobile_number": "01712345678",
            ...         "pin": "12345"
            ...     }
            ... )
            >>> print(result["success"])
            True
        """
        pass
    
    @abstractmethod
    async def get_transaction_status(
        self,
        transaction_id: str
    ) -> Dict[str, Any]:
        """
        Query the current status of a payment transaction.
        
        This method retrieves the current state of a transaction without
        modifying it. Useful for checking payment status after initialization
        or for reconciliation purposes.
        
        Args:
            transaction_id: Unique transaction identifier
        
        Returns:
            Dictionary containing:
                - transaction_id (str): Transaction identifier (echoed back)
                - status (str): Current transaction status
                              ("pending", "success", "failed", "not_found")
                - amount (float): Payment amount
                - created_at (str): ISO 8601 timestamp of transaction creation
                - Additional gateway-specific fields as needed
        
        Raises:
            ValueError: If transaction_id format is invalid
            ConnectionError: If gateway communication fails
            
        Example:
            >>> status = await gateway.get_transaction_status("TXN_ABC123DEF456")
            >>> print(status["status"])
            success
        """
        pass
