"""
Tests for payment Pydantic models.

Validates that all payment models have correct validation rules and field descriptions.
"""

import pytest
from datetime import datetime
from pydantic import ValidationError

from app.models.payments import (
    PaymentInitRequest,
    PaymentVerifyRequest,
    PaymentInitResponse,
    PaymentVerifyResponse,
    SubscriptionStatusResponse,
    TransactionDetail,
    PaymentHistoryResponse
)


class TestPaymentInitRequest:
    """Tests for PaymentInitRequest model."""
    
    def test_valid_bkash_request(self):
        """Test creating valid bKash payment request."""
        request = PaymentInitRequest(
            user_id="test_user_123",
            payment_method="bkash",
            amount=999.00,
            currency="BDT"
        )
        assert request.user_id == "test_user_123"
        assert request.payment_method == "bkash"
        assert request.amount == 999.00
        assert request.currency == "BDT"
    
    def test_valid_card_request(self):
        """Test creating valid card payment request."""
        request = PaymentInitRequest(
            user_id="test_user_456",
            payment_method="credit_card",
            amount=1500.50
        )
        assert request.payment_method == "credit_card"
        assert request.currency == "BDT"  # Default value
    
    def test_invalid_payment_method(self):
        """Test that invalid payment method raises validation error."""
        with pytest.raises(ValidationError) as exc_info:
            PaymentInitRequest(
                user_id="test_user",
                payment_method="paypal",  # Invalid method
                amount=100.00
            )
        assert "payment_method" in str(exc_info.value)
    
    def test_negative_amount(self):
        """Test that negative amount raises validation error."""
        with pytest.raises(ValidationError) as exc_info:
            PaymentInitRequest(
                user_id="test_user",
                payment_method="bkash",
                amount=-50.00  # Invalid negative amount
            )
        assert "amount" in str(exc_info.value)
    
    def test_zero_amount(self):
        """Test that zero amount raises validation error."""
        with pytest.raises(ValidationError) as exc_info:
            PaymentInitRequest(
                user_id="test_user",
                payment_method="bkash",
                amount=0.00  # Invalid zero amount
            )
        assert "amount" in str(exc_info.value)
    
    def test_currency_uppercase_conversion(self):
        """Test that currency is converted to uppercase."""
        request = PaymentInitRequest(
            user_id="test_user",
            payment_method="bkash",
            amount=100.00,
            currency="bdt"  # Lowercase
        )
        assert request.currency == "BDT"  # Should be uppercase


class TestPaymentVerifyRequest:
    """Tests for PaymentVerifyRequest model."""
    
    def test_valid_bkash_verify_request(self):
        """Test creating valid bKash verification request."""
        request = PaymentVerifyRequest(
            transaction_id="TXN_ABC123",
            payment_credentials={
                "mobile_number": "01712345678",
                "pin": "12345"
            }
        )
        assert request.transaction_id == "TXN_ABC123"
        assert request.payment_credentials["mobile_number"] == "01712345678"
    
    def test_valid_card_verify_request(self):
        """Test creating valid card verification request."""
        request = PaymentVerifyRequest(
            transaction_id="TXN_XYZ789",
            payment_credentials={
                "card_number": "4111111111111111",
                "cvv": "123",
                "expiry": "12/25"
            }
        )
        assert request.payment_credentials["card_number"] == "4111111111111111"


class TestPaymentInitResponse:
    """Tests for PaymentInitResponse model."""
    
    def test_valid_init_response(self):
        """Test creating valid payment initialization response."""
        response = PaymentInitResponse(
            success=True,
            transaction_id="TXN_TEST123",
            payment_url=None,
            message="Payment initialized successfully"
        )
        assert response.success is True
        assert response.transaction_id == "TXN_TEST123"
        assert response.payment_url is None
        assert response.message == "Payment initialized successfully"


class TestPaymentVerifyResponse:
    """Tests for PaymentVerifyResponse model."""
    
    def test_successful_verify_response(self):
        """Test creating successful payment verification response."""
        response = PaymentVerifyResponse(
            success=True,
            transaction_id="TXN_SUCCESS",
            amount=999.00,
            message="Payment successful",
            subscription_status="premium"
        )
        assert response.success is True
        assert response.subscription_status == "premium"
    
    def test_failed_verify_response(self):
        """Test creating failed payment verification response."""
        response = PaymentVerifyResponse(
            success=False,
            transaction_id="TXN_FAILED",
            amount=999.00,
            message="Invalid credentials",
            subscription_status=None
        )
        assert response.success is False
        assert response.subscription_status is None


class TestSubscriptionStatusResponse:
    """Tests for SubscriptionStatusResponse model."""
    
    def test_free_user_status(self):
        """Test subscription status for free user."""
        status = SubscriptionStatusResponse(
            plan="free",
            activated_at=None,
            expires_at=None,
            is_active=False
        )
        assert status.plan == "free"
        assert status.activated_at is None
        assert status.is_active is False
    
    def test_premium_user_status(self):
        """Test subscription status for premium user."""
        now = datetime.utcnow()
        status = SubscriptionStatusResponse(
            plan="premium",
            activated_at=now,
            expires_at=now,
            is_active=True
        )
        assert status.plan == "premium"
        assert status.activated_at == now
        assert status.is_active is True
    
    def test_invalid_plan(self):
        """Test that invalid plan raises validation error."""
        with pytest.raises(ValidationError) as exc_info:
            SubscriptionStatusResponse(
                plan="enterprise",  # Invalid plan
                is_active=True
            )
        assert "plan" in str(exc_info.value)


class TestTransactionDetail:
    """Tests for TransactionDetail model."""
    
    def test_valid_transaction(self):
        """Test creating valid transaction detail."""
        now = datetime.utcnow()
        transaction = TransactionDetail(
            transaction_id="TXN_123",
            payment_method="bkash",
            amount=999.00,
            currency="BDT",
            status="success",
            created_at=now,
            verified_at=now
        )
        assert transaction.transaction_id == "TXN_123"
        assert transaction.status == "success"
        assert transaction.verified_at == now
    
    def test_pending_transaction(self):
        """Test creating pending transaction (no verified_at)."""
        now = datetime.utcnow()
        transaction = TransactionDetail(
            transaction_id="TXN_PENDING",
            payment_method="credit_card",
            amount=1500.00,
            currency="BDT",
            status="pending",
            created_at=now,
            verified_at=None
        )
        assert transaction.status == "pending"
        assert transaction.verified_at is None
    
    def test_invalid_status(self):
        """Test that invalid status raises validation error."""
        now = datetime.utcnow()
        with pytest.raises(ValidationError) as exc_info:
            TransactionDetail(
                transaction_id="TXN_123",
                payment_method="bkash",
                amount=999.00,
                currency="BDT",
                status="cancelled",  # Invalid status
                created_at=now
            )
        assert "status" in str(exc_info.value)


class TestPaymentHistoryResponse:
    """Tests for PaymentHistoryResponse model."""
    
    def test_empty_history(self):
        """Test payment history with no transactions."""
        history = PaymentHistoryResponse(
            transactions=[],
            total_count=0
        )
        assert len(history.transactions) == 0
        assert history.total_count == 0
    
    def test_history_with_transactions(self):
        """Test payment history with multiple transactions."""
        now = datetime.utcnow()
        transactions = [
            TransactionDetail(
                transaction_id=f"TXN_{i}",
                payment_method="bkash",
                amount=999.00,
                currency="BDT",
                status="success",
                created_at=now
            )
            for i in range(3)
        ]
        
        history = PaymentHistoryResponse(
            transactions=transactions,
            total_count=3
        )
        assert len(history.transactions) == 3
        assert history.total_count == 3
    
    def test_negative_total_count(self):
        """Test that negative total_count raises validation error."""
        with pytest.raises(ValidationError) as exc_info:
            PaymentHistoryResponse(
                transactions=[],
                total_count=-1  # Invalid negative count
            )
        assert "total_count" in str(exc_info.value)


class TestModelFieldDescriptions:
    """Tests to verify all models have proper field descriptions."""
    
    def test_payment_init_request_has_descriptions(self):
        """Test that PaymentInitRequest fields have descriptions."""
        schema = PaymentInitRequest.model_json_schema()
        properties = schema['properties']
        
        assert 'description' in properties['user_id']
        assert 'description' in properties['payment_method']
        assert 'description' in properties['amount']
        assert 'description' in properties['currency']
    
    def test_subscription_status_response_has_descriptions(self):
        """Test that SubscriptionStatusResponse fields have descriptions."""
        schema = SubscriptionStatusResponse.model_json_schema()
        properties = schema['properties']
        
        assert 'description' in properties['plan']
        assert 'description' in properties['is_active']
    
    def test_transaction_detail_has_descriptions(self):
        """Test that TransactionDetail fields have descriptions."""
        schema = TransactionDetail.model_json_schema()
        properties = schema['properties']
        
        assert 'description' in properties['transaction_id']
        assert 'description' in properties['payment_method']
        assert 'description' in properties['status']
