"""
Pydantic models for payment and subscription system.

This module defines request and response models for the payment API endpoints.
All models include validation rules and field descriptions for API documentation.
"""

from pydantic import BaseModel, Field, field_validator
from typing import Optional, Dict, Any, List
from datetime import datetime
from decimal import Decimal


class PaymentInitRequest(BaseModel):
    """Request model for initializing a payment transaction."""
    
    user_id: str = Field(
        ...,
        description="Google sub claim (user identifier)",
        min_length=1
    )
    payment_method: str = Field(
        ...,
        description="Payment method: 'bkash', 'debit_card', or 'credit_card'"
    )
    amount: float = Field(
        ...,
        gt=0,
        description="Payment amount (must be greater than 0)"
    )
    currency: str = Field(
        default="BDT",
        description="Currency code (default: BDT)",
        min_length=3,
        max_length=3
    )
    
    @field_validator('payment_method')
    @classmethod
    def validate_payment_method(cls, v: str) -> str:
        """Validate payment method is one of the supported types."""
        allowed_methods = ['bkash', 'debit_card', 'credit_card']
        if v not in allowed_methods:
            raise ValueError(f"Payment method must be one of: {', '.join(allowed_methods)}")
        return v
    
    @field_validator('currency')
    @classmethod
    def validate_currency(cls, v: str) -> str:
        """Validate currency code is uppercase."""
        return v.upper()


class PaymentVerifyRequest(BaseModel):
    """Request model for verifying a payment transaction."""
    
    transaction_id: str = Field(
        ...,
        description="Transaction ID from payment initialization",
        min_length=1
    )
    payment_credentials: Dict[str, Any] = Field(
        ...,
        description=(
            "Payment method specific credentials. "
            "For bKash: {'mobile_number': str, 'pin': str}. "
            "For Card: {'card_number': str, 'cvv': str, 'expiry': str}"
        )
    )


class PaymentInitResponse(BaseModel):
    """Response model for payment initialization."""
    
    success: bool = Field(
        ...,
        description="Whether initialization was successful"
    )
    transaction_id: str = Field(
        ...,
        description="Unique transaction identifier"
    )
    payment_url: Optional[str] = Field(
        None,
        description="Payment gateway URL (None for mock gateway)"
    )
    message: str = Field(
        ...,
        description="Human-readable status message"
    )


class PaymentVerifyResponse(BaseModel):
    """Response model for payment verification."""
    
    success: bool = Field(
        ...,
        description="Whether payment was successful"
    )
    transaction_id: str = Field(
        ...,
        description="Transaction identifier"
    )
    amount: float = Field(
        ...,
        description="Payment amount"
    )
    message: str = Field(
        ...,
        description="Human-readable result message"
    )
    subscription_status: Optional[str] = Field(
        None,
        description="Updated subscription status ('free' or 'premium')"
    )


class SubscriptionStatusResponse(BaseModel):
    """Response model for subscription status query."""
    
    plan: str = Field(
        ...,
        description="Subscription plan: 'free' or 'premium'"
    )
    activated_at: Optional[datetime] = Field(
        None,
        description="Timestamp when premium was activated (None for free users)"
    )
    expires_at: Optional[datetime] = Field(
        None,
        description="Timestamp when premium expires (None for free users)"
    )
    is_active: bool = Field(
        ...,
        description="Whether the subscription is currently active"
    )
    
    @field_validator('plan')
    @classmethod
    def validate_plan(cls, v: str) -> str:
        """Validate plan is either 'free' or 'premium'."""
        allowed_plans = ['free', 'premium']
        if v not in allowed_plans:
            raise ValueError(f"Plan must be one of: {', '.join(allowed_plans)}")
        return v


class TransactionDetail(BaseModel):
    """Model for individual transaction details."""
    
    transaction_id: str = Field(
        ...,
        description="Unique transaction identifier"
    )
    payment_method: str = Field(
        ...,
        description="Payment method used: 'bkash', 'debit_card', or 'credit_card'"
    )
    amount: float = Field(
        ...,
        description="Transaction amount"
    )
    currency: str = Field(
        ...,
        description="Currency code (e.g., 'BDT')"
    )
    status: str = Field(
        ...,
        description="Transaction status: 'pending', 'success', or 'failed'"
    )
    created_at: datetime = Field(
        ...,
        description="Timestamp when transaction was created"
    )
    verified_at: Optional[datetime] = Field(
        None,
        description="Timestamp when transaction was verified (None if not verified)"
    )
    
    @field_validator('status')
    @classmethod
    def validate_status(cls, v: str) -> str:
        """Validate status is one of the allowed values."""
        allowed_statuses = ['pending', 'success', 'failed']
        if v not in allowed_statuses:
            raise ValueError(f"Status must be one of: {', '.join(allowed_statuses)}")
        return v


class PaymentHistoryResponse(BaseModel):
    """Response model for payment history query."""
    
    transactions: List[TransactionDetail] = Field(
        ...,
        description="List of transaction records"
    )
    total_count: int = Field(
        ...,
        ge=0,
        description="Total number of transactions for the user"
    )
