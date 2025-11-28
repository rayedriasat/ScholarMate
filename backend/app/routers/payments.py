"""Payment and subscription endpoints"""
import logging
from datetime import datetime
from fastapi import APIRouter, HTTPException, status
from ..models.payments import (
    PaymentInitRequest,
    PaymentInitResponse,
    PaymentVerifyRequest,
    PaymentVerifyResponse,
    SubscriptionStatusResponse,
    PaymentHistoryResponse,
    TransactionDetail
)
from ..services.payment_gateway_factory import get_payment_gateway
from ..services.subscription_service import get_subscription_service
from ..services.supabase_service import get_supabase_service

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/payments", tags=["payments"])


@router.post("/initialize", response_model=PaymentInitResponse)
async def initialize_payment(request: PaymentInitRequest):
    """
    Initialize a payment transaction
    
    This endpoint:
    1. Validates the payment request
    2. Calls the payment gateway to initialize the transaction
    3. Records the transaction in the database with 'pending' status
    4. Returns the transaction ID and status
    
    Args:
        request: Payment initialization request with user_id, payment_method, amount, currency
        
    Returns:
        PaymentInitResponse with transaction_id, payment_url (None for mock), and message
        
    Raises:
        HTTPException: If user not found, validation fails, or gateway error occurs
    """
    try:
        # Log payment initiation
        logger.info(
            f"Payment initialization started: user={request.user_id}, "
            f"method={request.payment_method}, amount={request.amount} {request.currency}",
            extra={
                "user_id": request.user_id,
                "payment_method": request.payment_method,
                "amount": request.amount,
                "currency": request.currency
            }
        )
        
        # Get services
        supabase_service = get_supabase_service()
        payment_gateway = get_payment_gateway()
        subscription_service = get_subscription_service()
        
        # Get user from database by google_sub
        user_response = supabase_service.client.table("users").select("id").eq(
            "google_sub", request.user_id
        ).execute()
        
        if not user_response.data or len(user_response.data) == 0:
            logger.warning(f"User not found: {request.user_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User not found: {request.user_id}"
            )
        
        db_user_id = user_response.data[0]["id"]
        
        # Initialize payment with gateway
        gateway_response = await payment_gateway.initialize_payment(
            amount=request.amount,
            currency=request.currency,
            payment_method=request.payment_method,
            user_id=request.user_id,
            metadata={
                "db_user_id": db_user_id,
                "initiated_at": None  # Will be set by gateway
            }
        )
        
        transaction_id = gateway_response["transaction_id"]
        
        # Record transaction in database with 'pending' status
        await subscription_service.record_transaction(
            user_id=db_user_id,
            transaction_id=transaction_id,
            payment_method=request.payment_method,
            amount=request.amount,
            status="pending",
            currency=request.currency,
            metadata={
                "gateway_response": gateway_response
            }
        )
        
        logger.info(
            f"Payment initialized successfully: transaction_id={transaction_id}, "
            f"user={request.user_id}",
            extra={
                "transaction_id": transaction_id,
                "user_id": request.user_id
            }
        )
        
        return PaymentInitResponse(
            success=True,
            transaction_id=transaction_id,
            payment_url=gateway_response.get("payment_url"),
            message="Payment initialized successfully"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(
            f"Payment initialization failed: user={request.user_id}, error={str(e)}",
            extra={
                "user_id": request.user_id,
                "error": str(e)
            },
            exc_info=True
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to initialize payment: {str(e)}"
        )


@router.post("/verify", response_model=PaymentVerifyResponse)
async def verify_payment(request: PaymentVerifyRequest):
    """
    Verify payment and activate subscription
    
    This endpoint:
    1. Validates the transaction exists
    2. Calls the payment gateway to verify payment credentials
    3. If successful, activates premium subscription
    4. Records the transaction result in the database
    5. Returns verification result with subscription status
    
    Args:
        request: Payment verification request with transaction_id and payment_credentials
        
    Returns:
        PaymentVerifyResponse with success status, transaction details, and subscription status
        
    Raises:
        HTTPException: If transaction not found, verification fails, or database error occurs
    """
    try:
        # Log payment verification attempt
        logger.info(
            f"Payment verification started: transaction_id={request.transaction_id}",
            extra={
                "transaction_id": request.transaction_id
            }
        )
        
        # Get services
        supabase_service = get_supabase_service()
        payment_gateway = get_payment_gateway()
        subscription_service = get_subscription_service()
        
        # Get transaction from database to retrieve user_id
        transaction_response = supabase_service.client.table("transactions").select(
            "user_id, amount, payment_method, status"
        ).eq("transaction_id", request.transaction_id).execute()
        
        if not transaction_response.data or len(transaction_response.data) == 0:
            logger.warning(f"Transaction not found: {request.transaction_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Transaction not found: {request.transaction_id}"
            )
        
        transaction_data = transaction_response.data[0]
        db_user_id = transaction_data["user_id"]
        amount = transaction_data["amount"]
        payment_method = transaction_data["payment_method"]
        current_status = transaction_data["status"]
        
        # Check if transaction is already verified
        if current_status in ["success", "failed"]:
            logger.warning(
                f"Transaction already verified: {request.transaction_id}, status={current_status}"
            )
            return PaymentVerifyResponse(
                success=(current_status == "success"),
                transaction_id=request.transaction_id,
                amount=amount,
                message=f"Transaction already {current_status}",
                subscription_status="premium" if current_status == "success" else None
            )
        
        # Verify payment with gateway
        gateway_response = await payment_gateway.verify_payment(
            transaction_id=request.transaction_id,
            payment_credentials=request.payment_credentials
        )
        
        success = gateway_response["success"]
        message = gateway_response["message"]
        
        # Update transaction status in database
        new_status = "success" if success else "failed"
        update_data = {
            "status": new_status,
            "verified_at": datetime.utcnow().isoformat()
        }
        
        supabase_service.client.table("transactions").update(update_data).eq(
            "transaction_id", request.transaction_id
        ).execute()
        
        subscription_status = None
        
        # If payment successful, activate premium subscription
        if success:
            try:
                subscription_result = await subscription_service.activate_premium(
                    user_id=db_user_id,
                    transaction_id=request.transaction_id,
                    duration_days=365  # 1 year subscription
                )
                subscription_status = subscription_result["plan"]
                
                logger.info(
                    f"Payment verified successfully and premium activated: "
                    f"transaction_id={request.transaction_id}, user_id={db_user_id}",
                    extra={
                        "transaction_id": request.transaction_id,
                        "user_id": db_user_id,
                        "subscription_status": subscription_status
                    }
                )
            except Exception as e:
                logger.error(
                    f"Payment verified but premium activation failed: "
                    f"transaction_id={request.transaction_id}, error={str(e)}",
                    extra={
                        "transaction_id": request.transaction_id,
                        "error": str(e)
                    },
                    exc_info=True
                )
                # Still return success for payment, but note activation failure
                message = f"Payment successful but subscription activation failed: {str(e)}"
        else:
            logger.info(
                f"Payment verification failed: transaction_id={request.transaction_id}, "
                f"reason={message}",
                extra={
                    "transaction_id": request.transaction_id,
                    "message": message
                }
            )
        
        return PaymentVerifyResponse(
            success=success,
            transaction_id=request.transaction_id,
            amount=amount,
            message=message,
            subscription_status=subscription_status
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(
            f"Payment verification failed: transaction_id={request.transaction_id}, "
            f"error={str(e)}",
            extra={
                "transaction_id": request.transaction_id,
                "error": str(e)
            },
            exc_info=True
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to verify payment: {str(e)}"
        )


@router.get("/subscription-status", response_model=SubscriptionStatusResponse)
async def get_subscription_status(user_id: str):
    """
    Get current subscription status for user
    
    This endpoint:
    1. Validates the user exists
    2. Queries the subscription service for current status
    3. Returns plan type, activation date, expiry date, and active status
    
    Args:
        user_id: Google sub claim (user identifier)
        
    Returns:
        SubscriptionStatusResponse with plan, activated_at, expires_at, and is_active
        
    Raises:
        HTTPException: If user not found or database error occurs
    """
    try:
        logger.info(
            f"Subscription status query: user={user_id}",
            extra={"user_id": user_id}
        )
        
        # Get services
        supabase_service = get_supabase_service()
        subscription_service = get_subscription_service()
        
        # Get user from database by google_sub
        user_response = supabase_service.client.table("users").select("id").eq(
            "google_sub", user_id
        ).execute()
        
        if not user_response.data or len(user_response.data) == 0:
            logger.warning(f"User not found: {user_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User not found: {user_id}"
            )
        
        db_user_id = user_response.data[0]["id"]
        
        # Get subscription status from service
        status_data = await subscription_service.get_subscription_status(db_user_id)
        
        # Parse datetime strings to datetime objects for response model
        activated_at = None
        expires_at = None
        
        if status_data.get("activated_at"):
            try:
                activated_at = datetime.fromisoformat(
                    status_data["activated_at"].replace('Z', '+00:00')
                )
            except (ValueError, AttributeError) as e:
                logger.warning(
                    f"Invalid activated_at format for user {user_id}: "
                    f"{status_data.get('activated_at')}, error: {str(e)}"
                )
        
        if status_data.get("expires_at"):
            try:
                expires_at = datetime.fromisoformat(
                    status_data["expires_at"].replace('Z', '+00:00')
                )
            except (ValueError, AttributeError) as e:
                logger.warning(
                    f"Invalid expires_at format for user {user_id}: "
                    f"{status_data.get('expires_at')}, error: {str(e)}"
                )
        
        logger.info(
            f"Subscription status retrieved: user={user_id}, plan={status_data['plan']}, "
            f"is_active={status_data['is_active']}",
            extra={
                "user_id": user_id,
                "plan": status_data["plan"],
                "is_active": status_data["is_active"]
            }
        )
        
        return SubscriptionStatusResponse(
            plan=status_data["plan"],
            activated_at=activated_at,
            expires_at=expires_at,
            is_active=status_data["is_active"]
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(
            f"Failed to get subscription status: user={user_id}, error={str(e)}",
            extra={
                "user_id": user_id,
                "error": str(e)
            },
            exc_info=True
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get subscription status: {str(e)}"
        )


@router.get("/history", response_model=PaymentHistoryResponse)
async def get_payment_history(
    user_id: str,
    limit: int = 50,
    offset: int = 0
):
    """
    Get payment transaction history for user
    
    This endpoint:
    1. Validates the user exists
    2. Queries the subscription service for payment history
    3. Returns list of transactions with all details (transaction ID, amount, date, status)
    4. Supports pagination via limit and offset parameters
    
    Args:
        user_id: Google sub claim (user identifier)
        limit: Maximum number of transactions to return (default: 50, max: 100)
        offset: Number of transactions to skip for pagination (default: 0)
        
    Returns:
        PaymentHistoryResponse with list of transactions and total count
        
    Raises:
        HTTPException: If user not found, invalid parameters, or database error occurs
    """
    try:
        # Validate pagination parameters
        if limit <= 0 or limit > 100:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Limit must be between 1 and 100"
            )
        
        if offset < 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Offset must be non-negative"
            )
        
        logger.info(
            f"Payment history query: user={user_id}, limit={limit}, offset={offset}",
            extra={
                "user_id": user_id,
                "limit": limit,
                "offset": offset
            }
        )
        
        # Get services
        supabase_service = get_supabase_service()
        subscription_service = get_subscription_service()
        
        # Get user from database by google_sub
        user_response = supabase_service.client.table("users").select("id").eq(
            "google_sub", user_id
        ).execute()
        
        if not user_response.data or len(user_response.data) == 0:
            logger.warning(f"User not found: {user_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"User not found: {user_id}"
            )
        
        db_user_id = user_response.data[0]["id"]
        
        # Get payment history from service
        transactions_data = await subscription_service.get_payment_history(
            user_id=db_user_id,
            limit=limit,
            offset=offset
        )
        
        # Get total count of transactions for this user
        count_response = supabase_service.client.table("transactions").select(
            "id", count="exact"
        ).eq("user_id", db_user_id).execute()
        
        total_count = count_response.count if count_response.count is not None else 0
        
        # Convert transaction data to TransactionDetail models
        transactions = []
        for txn in transactions_data:
            # Parse datetime strings
            created_at = datetime.fromisoformat(
                txn["created_at"].replace('Z', '+00:00')
            )
            
            verified_at = None
            if txn.get("verified_at"):
                try:
                    verified_at = datetime.fromisoformat(
                        txn["verified_at"].replace('Z', '+00:00')
                    )
                except (ValueError, AttributeError) as e:
                    logger.warning(
                        f"Invalid verified_at format for transaction {txn['transaction_id']}: "
                        f"{txn.get('verified_at')}, error: {str(e)}"
                    )
            
            transactions.append(TransactionDetail(
                transaction_id=txn["transaction_id"],
                payment_method=txn["payment_method"],
                amount=float(txn["amount"]),
                currency=txn["currency"],
                status=txn["status"],
                created_at=created_at,
                verified_at=verified_at
            ))
        
        logger.info(
            f"Payment history retrieved: user={user_id}, "
            f"returned={len(transactions)}, total={total_count}",
            extra={
                "user_id": user_id,
                "returned_count": len(transactions),
                "total_count": total_count
            }
        )
        
        return PaymentHistoryResponse(
            transactions=transactions,
            total_count=total_count
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(
            f"Failed to get payment history: user={user_id}, error={str(e)}",
            extra={
                "user_id": user_id,
                "error": str(e)
            },
            exc_info=True
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get payment history: {str(e)}"
        )
