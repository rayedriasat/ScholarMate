"""
Basic tests for payment gateway implementation.

This file contains simple tests to verify the payment gateway abstraction
layer is working correctly before proceeding with property-based tests.
"""

import pytest
import asyncio
from app.services.payment_gateway_factory import get_payment_gateway
from app.services.mock_payment_gateway import MockPaymentGateway
from app.services.payment_gateway_interface import PaymentGatewayInterface


@pytest.mark.asyncio
async def test_factory_returns_mock_gateway():
    """Test that factory returns MockPaymentGateway by default."""
    gateway = get_payment_gateway()
    assert isinstance(gateway, MockPaymentGateway)
    assert isinstance(gateway, PaymentGatewayInterface)


@pytest.mark.asyncio
async def test_initialize_payment_creates_transaction():
    """Test that initialize_payment creates a transaction with unique ID."""
    gateway = MockPaymentGateway()
    
    result = await gateway.initialize_payment(
        amount=999.00,
        currency="BDT",
        payment_method="bkash",
        user_id="test_user_123",
        metadata={"subscription_type": "premium"}
    )
    
    assert "transaction_id" in result
    assert result["transaction_id"].startswith("TXN_")
    assert result["status"] == "pending"
    assert result["payment_url"] is None


@pytest.mark.asyncio
async def test_verify_payment_success_bkash():
    """Test successful bKash payment verification."""
    gateway = MockPaymentGateway()
    
    # Initialize payment
    init_result = await gateway.initialize_payment(
        amount=999.00,
        currency="BDT",
        payment_method="bkash",
        user_id="test_user_123",
        metadata={}
    )
    
    transaction_id = init_result["transaction_id"]
    
    # Verify with correct credentials
    verify_result = await gateway.verify_payment(
        transaction_id=transaction_id,
        payment_credentials={
            "mobile_number": "01712345678",
            "pin": "12345"
        }
    )
    
    assert verify_result["success"] is True
    assert verify_result["transaction_id"] == transaction_id
    assert verify_result["amount"] == 999.00
    assert "successful" in verify_result["message"].lower()


@pytest.mark.asyncio
async def test_verify_payment_failure_bkash_wrong_pin():
    """Test failed bKash payment with wrong PIN."""
    gateway = MockPaymentGateway()
    
    # Initialize payment
    init_result = await gateway.initialize_payment(
        amount=999.00,
        currency="BDT",
        payment_method="bkash",
        user_id="test_user_123",
        metadata={}
    )
    
    transaction_id = init_result["transaction_id"]
    
    # Verify with wrong PIN
    verify_result = await gateway.verify_payment(
        transaction_id=transaction_id,
        payment_credentials={
            "mobile_number": "01712345678",
            "pin": "99999"  # Wrong PIN
        }
    )
    
    assert verify_result["success"] is False
    assert "invalid" in verify_result["message"].lower()


@pytest.mark.asyncio
async def test_verify_payment_success_card():
    """Test successful card payment verification."""
    gateway = MockPaymentGateway()
    
    # Initialize payment
    init_result = await gateway.initialize_payment(
        amount=999.00,
        currency="BDT",
        payment_method="credit_card",
        user_id="test_user_123",
        metadata={}
    )
    
    transaction_id = init_result["transaction_id"]
    
    # Verify with correct credentials
    verify_result = await gateway.verify_payment(
        transaction_id=transaction_id,
        payment_credentials={
            "card_number": "4111111111111111",
            "cvv": "123",
            "expiry": "12/25"  # Future date
        }
    )
    
    assert verify_result["success"] is True
    assert verify_result["transaction_id"] == transaction_id
    assert verify_result["amount"] == 999.00


@pytest.mark.asyncio
async def test_verify_payment_failure_card_wrong_number():
    """Test failed card payment with wrong card number."""
    gateway = MockPaymentGateway()
    
    # Initialize payment
    init_result = await gateway.initialize_payment(
        amount=999.00,
        currency="BDT",
        payment_method="credit_card",
        user_id="test_user_123",
        metadata={}
    )
    
    transaction_id = init_result["transaction_id"]
    
    # Verify with wrong card number
    verify_result = await gateway.verify_payment(
        transaction_id=transaction_id,
        payment_credentials={
            "card_number": "1234567890123456",  # Wrong number
            "cvv": "123",
            "expiry": "12/25"
        }
    )
    
    assert verify_result["success"] is False
    assert "invalid" in verify_result["message"].lower()


@pytest.mark.asyncio
async def test_get_transaction_status():
    """Test getting transaction status."""
    gateway = MockPaymentGateway()
    
    # Initialize payment
    init_result = await gateway.initialize_payment(
        amount=999.00,
        currency="BDT",
        payment_method="bkash",
        user_id="test_user_123",
        metadata={}
    )
    
    transaction_id = init_result["transaction_id"]
    
    # Get status
    status = await gateway.get_transaction_status(transaction_id)
    
    assert status["transaction_id"] == transaction_id
    assert status["status"] == "pending"
    assert status["amount"] == 999.00
    assert status["created_at"] is not None


@pytest.mark.asyncio
async def test_get_transaction_status_not_found():
    """Test getting status for non-existent transaction."""
    gateway = MockPaymentGateway()
    
    status = await gateway.get_transaction_status("TXN_NONEXISTENT")
    
    assert status["status"] == "not_found"
    assert status["amount"] == 0


@pytest.mark.asyncio
async def test_initialize_payment_invalid_amount():
    """Test that negative amount raises ValueError."""
    gateway = MockPaymentGateway()
    
    with pytest.raises(ValueError, match="Amount must be positive"):
        await gateway.initialize_payment(
            amount=-100.00,
            currency="BDT",
            payment_method="bkash",
            user_id="test_user_123",
            metadata={}
        )


@pytest.mark.asyncio
async def test_initialize_payment_invalid_method():
    """Test that invalid payment method raises ValueError."""
    gateway = MockPaymentGateway()
    
    with pytest.raises(ValueError, match="Invalid payment method"):
        await gateway.initialize_payment(
            amount=999.00,
            currency="BDT",
            payment_method="invalid_method",
            user_id="test_user_123",
            metadata={}
        )


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
