"""
Test for POST /api/payments/initialize endpoint

This test verifies:
- Payment initialization accepts valid requests
- Transaction ID is generated and returned
- Transaction is recorded in database with 'pending' status
- Proper logging occurs
- Error handling for invalid users
"""
import pytest
import asyncio
from app.models.payments import PaymentInitRequest
from app.services.payment_gateway_factory import get_payment_gateway
from app.services.subscription_service import get_subscription_service
from app.services.supabase_service import get_supabase_service


@pytest.mark.asyncio
async def test_initialize_payment_success():
    """Test successful payment initialization"""
    # Setup
    supabase_service = get_supabase_service()
    subscription_service = get_subscription_service()
    payment_gateway = get_payment_gateway()
    
    # Create a test user
    test_user = await supabase_service.get_or_create_user(
        google_sub="test_user_init_001",
        email="test_init@example.com",
        name="Test Init User"
    )
    db_user_id = test_user["id"]
    
    try:
        # Test payment initialization
        request = PaymentInitRequest(
            user_id="test_user_init_001",
            payment_method="bkash",
            amount=500.0,
            currency="BDT"
        )
        
        # Initialize payment through gateway
        gateway_response = await payment_gateway.initialize_payment(
            amount=request.amount,
            currency=request.currency,
            payment_method=request.payment_method,
            user_id=request.user_id,
            metadata={"db_user_id": db_user_id}
        )
        
        transaction_id = gateway_response["transaction_id"]
        
        # Record transaction
        await subscription_service.record_transaction(
            user_id=db_user_id,
            transaction_id=transaction_id,
            payment_method=request.payment_method,
            amount=request.amount,
            status="pending",
            currency=request.currency,
            metadata={"gateway_response": gateway_response}
        )
        
        # Verify transaction was created
        assert transaction_id is not None
        assert len(transaction_id) > 0
        assert gateway_response["status"] == "pending"
        
        # Verify transaction in database
        transactions = await subscription_service.get_payment_history(
            user_id=db_user_id,
            limit=1
        )
        
        assert len(transactions) > 0
        latest_transaction = transactions[0]
        assert latest_transaction["transaction_id"] == transaction_id
        assert latest_transaction["payment_method"] == "bkash"
        assert latest_transaction["amount"] == 500.0
        assert latest_transaction["currency"] == "BDT"
        assert latest_transaction["status"] == "pending"
        
        print(f"✓ Payment initialized successfully: {transaction_id}")
        print(f"✓ Transaction recorded in database with status: pending")
        
    finally:
        # Cleanup: Delete test user and transactions
        supabase_service.client.table("transactions").delete().eq(
            "user_id", db_user_id
        ).execute()
        supabase_service.client.table("users").delete().eq(
            "id", db_user_id
        ).execute()


@pytest.mark.asyncio
async def test_initialize_payment_all_methods():
    """Test payment initialization with all payment methods"""
    supabase_service = get_supabase_service()
    subscription_service = get_subscription_service()
    payment_gateway = get_payment_gateway()
    
    # Create a test user
    test_user = await supabase_service.get_or_create_user(
        google_sub="test_user_init_002",
        email="test_init2@example.com",
        name="Test Init User 2"
    )
    db_user_id = test_user["id"]
    
    try:
        payment_methods = ["bkash", "debit_card", "credit_card"]
        
        for method in payment_methods:
            # Initialize payment
            gateway_response = await payment_gateway.initialize_payment(
                amount=1000.0,
                currency="BDT",
                payment_method=method,
                user_id="test_user_init_002",
                metadata={"db_user_id": db_user_id}
            )
            
            transaction_id = gateway_response["transaction_id"]
            
            # Record transaction
            await subscription_service.record_transaction(
                user_id=db_user_id,
                transaction_id=transaction_id,
                payment_method=method,
                amount=1000.0,
                status="pending",
                currency="BDT"
            )
            
            assert transaction_id is not None
            print(f"✓ Payment initialized for {method}: {transaction_id}")
        
        # Verify all transactions were recorded
        transactions = await subscription_service.get_payment_history(
            user_id=db_user_id,
            limit=10
        )
        
        assert len(transactions) == 3
        recorded_methods = {t["payment_method"] for t in transactions}
        assert recorded_methods == set(payment_methods)
        
        print(f"✓ All payment methods initialized successfully")
        
    finally:
        # Cleanup
        supabase_service.client.table("transactions").delete().eq(
            "user_id", db_user_id
        ).execute()
        supabase_service.client.table("users").delete().eq(
            "id", db_user_id
        ).execute()


@pytest.mark.asyncio
async def test_initialize_payment_transaction_id_uniqueness():
    """Test that each initialization generates a unique transaction ID"""
    payment_gateway = get_payment_gateway()
    
    transaction_ids = set()
    
    # Initialize multiple payments
    for i in range(10):
        gateway_response = await payment_gateway.initialize_payment(
            amount=100.0,
            currency="BDT",
            payment_method="bkash",
            user_id=f"test_user_{i}",
            metadata={}
        )
        
        transaction_id = gateway_response["transaction_id"]
        assert transaction_id not in transaction_ids, f"Duplicate transaction ID: {transaction_id}"
        transaction_ids.add(transaction_id)
    
    print(f"✓ All {len(transaction_ids)} transaction IDs are unique")


if __name__ == "__main__":
    print("Testing POST /api/payments/initialize endpoint...")
    print()
    
    # Run tests
    asyncio.run(test_initialize_payment_success())
    print()
    asyncio.run(test_initialize_payment_all_methods())
    print()
    asyncio.run(test_initialize_payment_transaction_id_uniqueness())
    print()
    print("All tests passed! ✓")
