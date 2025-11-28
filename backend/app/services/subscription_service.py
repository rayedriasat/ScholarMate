"""Subscription management service"""
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
from supabase import Client
from .supabase_service import get_supabase_service

logger = logging.getLogger(__name__)


class SubscriptionService:
    """
    Service for managing user subscriptions and payment transactions.
    
    Responsibilities:
    - Activate premium subscriptions after successful payment
    - Query subscription status for users
    - Record payment transactions
    - Retrieve payment history with pagination
    """
    
    def __init__(self, supabase_client: Optional[Client] = None):
        """
        Initialize SubscriptionService
        
        Args:
            supabase_client: Optional Supabase client. If not provided, uses singleton.
        """
        if supabase_client:
            self.supabase = supabase_client
        else:
            supabase_service = get_supabase_service()
            self.supabase = supabase_service.client
    
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
            duration_days: Subscription duration in days (default 1 year)
        
        Returns:
            Updated subscription details with keys:
            - plan: "premium"
            - activated_at: ISO timestamp
            - expires_at: ISO timestamp
            - is_active: True
        
        Raises:
            ValueError: If user_id is invalid or user not found
            Exception: If database operation fails
        """
        try:
            # Calculate activation and expiry timestamps
            activated_at = datetime.utcnow()
            expires_at = activated_at + timedelta(days=duration_days)
            
            # Update user subscription status
            update_data = {
                "subscription_status": "premium",
                "subscription_activated_at": activated_at.isoformat(),
                "subscription_expires_at": expires_at.isoformat(),
                "updated_at": activated_at.isoformat()
            }
            
            response = self.supabase.table("users").update(update_data).eq("id", user_id).execute()
            
            if not response.data or len(response.data) == 0:
                raise ValueError(f"User not found with id: {user_id}")
            
            logger.info(
                f"Premium subscription activated for user {user_id}, "
                f"transaction {transaction_id}, expires {expires_at.isoformat()}"
            )
            
            return {
                "plan": "premium",
                "activated_at": activated_at.isoformat(),
                "expires_at": expires_at.isoformat(),
                "is_active": True
            }
            
        except Exception as e:
            logger.error(
                f"Failed to activate premium for user {user_id}, "
                f"transaction {transaction_id}: {str(e)}"
            )
            raise
    
    async def get_subscription_status(
        self,
        user_id: str
    ) -> Dict[str, Any]:
        """
        Get current subscription status for user
        
        Args:
            user_id: Database user ID (UUID)
        
        Returns:
            Dictionary with keys:
            - plan: "free" or "premium"
            - activated_at: ISO timestamp or None
            - expires_at: ISO timestamp or None
            - is_active: Boolean indicating if subscription is currently active
        
        Raises:
            ValueError: If user not found
            Exception: If database operation fails
        """
        try:
            # Query user subscription fields
            response = self.supabase.table("users").select(
                "subscription_status, subscription_activated_at, subscription_expires_at"
            ).eq("id", user_id).execute()
            
            if not response.data or len(response.data) == 0:
                raise ValueError(f"User not found with id: {user_id}")
            
            user = response.data[0]
            plan = user.get("subscription_status", "free")
            activated_at = user.get("subscription_activated_at")
            expires_at = user.get("subscription_expires_at")
            
            # Check if subscription is active
            is_active = False
            if plan == "premium" and expires_at:
                # Parse expiry date and check if it's in the future
                try:
                    expiry_date = datetime.fromisoformat(expires_at.replace('Z', '+00:00'))
                    # Use timezone-aware datetime for comparison
                    from datetime import timezone
                    now_utc = datetime.now(timezone.utc)
                    is_active = expiry_date > now_utc
                except (ValueError, AttributeError):
                    logger.warning(f"Invalid expiry date for user {user_id}: {expires_at}")
                    is_active = False
            
            return {
                "plan": plan,
                "activated_at": activated_at,
                "expires_at": expires_at,
                "is_active": is_active
            }
            
        except Exception as e:
            logger.error(f"Failed to get subscription status for user {user_id}: {str(e)}")
            raise
    
    async def record_transaction(
        self,
        user_id: str,
        transaction_id: str,
        payment_method: str,
        amount: float,
        status: str,
        currency: str = "BDT",
        metadata: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Record payment transaction in database
        
        Args:
            user_id: Database user ID (UUID)
            transaction_id: Unique transaction identifier from payment gateway
            payment_method: Payment method (bkash, debit_card, credit_card)
            amount: Payment amount
            status: Transaction status (pending, success, failed)
            currency: Currency code (default: BDT)
            metadata: Additional payment details as JSON
        
        Returns:
            Created transaction record
        
        Raises:
            ValueError: If parameters are invalid
            Exception: If database operation fails
        """
        try:
            # Validate payment method
            valid_methods = ["bkash", "debit_card", "credit_card"]
            if payment_method not in valid_methods:
                raise ValueError(
                    f"Invalid payment method: {payment_method}. "
                    f"Must be one of: {', '.join(valid_methods)}"
                )
            
            # Validate status
            valid_statuses = ["pending", "success", "failed"]
            if status not in valid_statuses:
                raise ValueError(
                    f"Invalid status: {status}. "
                    f"Must be one of: {', '.join(valid_statuses)}"
                )
            
            # Validate amount
            if amount <= 0:
                raise ValueError(f"Amount must be positive, got: {amount}")
            
            # Prepare transaction data
            transaction_data = {
                "transaction_id": transaction_id,
                "user_id": user_id,
                "payment_method": payment_method,
                "amount": amount,
                "currency": currency,
                "status": status,
                "metadata": metadata or {}
            }
            
            # Add verified_at timestamp for completed transactions
            if status in ["success", "failed"]:
                transaction_data["verified_at"] = datetime.utcnow().isoformat()
            
            # Insert transaction record
            response = self.supabase.table("transactions").insert(transaction_data).execute()
            
            if not response.data or len(response.data) == 0:
                raise Exception("Failed to insert transaction record")
            
            logger.info(
                f"Transaction recorded: {transaction_id}, "
                f"user: {user_id}, method: {payment_method}, "
                f"amount: {amount} {currency}, status: {status}"
            )
            
            return response.data[0]
            
        except Exception as e:
            logger.error(
                f"Failed to record transaction {transaction_id} "
                f"for user {user_id}: {str(e)}"
            )
            raise
    
    async def get_payment_history(
        self,
        user_id: str,
        limit: int = 50,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """
        Get payment transaction history for user with pagination
        
        Args:
            user_id: Database user ID (UUID)
            limit: Maximum number of transactions to return (default: 50)
            offset: Number of transactions to skip for pagination (default: 0)
        
        Returns:
            List of transaction records, ordered by created_at descending
            Each record contains:
            - transaction_id: Unique transaction identifier
            - payment_method: Payment method used
            - amount: Payment amount
            - currency: Currency code
            - status: Transaction status
            - created_at: Creation timestamp
            - verified_at: Verification timestamp (if completed)
            - metadata: Additional details
        
        Raises:
            ValueError: If limit or offset are invalid
            Exception: If database operation fails
        """
        try:
            # Validate pagination parameters
            if limit <= 0:
                raise ValueError(f"Limit must be positive, got: {limit}")
            if offset < 0:
                raise ValueError(f"Offset must be non-negative, got: {offset}")
            
            # Query transactions for user, ordered by creation date descending
            response = self.supabase.table("transactions").select(
                "transaction_id, payment_method, amount, currency, status, "
                "created_at, verified_at, metadata"
            ).eq("user_id", user_id).order(
                "created_at", desc=True
            ).range(offset, offset + limit - 1).execute()
            
            transactions = response.data or []
            
            logger.info(
                f"Retrieved {len(transactions)} transactions for user {user_id} "
                f"(limit: {limit}, offset: {offset})"
            )
            
            return transactions
            
        except Exception as e:
            logger.error(
                f"Failed to get payment history for user {user_id}: {str(e)}"
            )
            raise


# Singleton instance
_subscription_service: Optional[SubscriptionService] = None


def get_subscription_service() -> SubscriptionService:
    """Get or create SubscriptionService singleton"""
    global _subscription_service
    if _subscription_service is None:
        _subscription_service = SubscriptionService()
    return _subscription_service
