"""
Test suite for GET /api/payments/history endpoint

This test verifies that the payment history endpoint:
1. Returns transaction history for a valid user
2. Filters transactions by user ID
3. Supports pagination with limit and offset
4. Returns all required transaction details
5. Handles invalid parameters correctly
6. Handles non-existent users correctly
"""

import pytest
from fastapi.testclient import TestClient
from datetime import datetime, timedelta
import sys
import os

# Add backend directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from app.main import app
from app.services.supabase_service import get_supabase_service

client = TestClient(app)


@pytest.fixture
def test_user():
    """Create a test user and clean up after test"""
    supabase_service = get_supabase_service()
    
    # Create test user
    test_google_sub = f"test_history_user_{datetime.utcnow().timestamp()}"
    user_data = {
        "google_sub": test_google_sub,
        "email": f"{test_google_sub}@test.com",
        "name": "Test History User",
        "subscription_status": "free"
    }
    
    user_response = supabase_service.client.table("users").insert(user_data).execute()
    user_id = user_response.data[0]["id"]
    
    yield {
        "google_sub": test_google_sub,
        "db_user_id": user_id
    }
    
    # Cleanup: Delete test transactions and user
    supabase_service.client.table("transactions").delete().eq("user_id", user_id).execute()
    supabase_service.client.table("users").delete().eq("id", user_id).execute()


@pytest.fixture
def test_transactions(test_user):
    """Create test transactions for the user"""
    supabase_service = get_supabase_service()
    user_id = test_user["db_user_id"]
    
    # Create multiple transactions with different statuses
    transactions = [
        {
            "transaction_id": "TXN_HIST_001",
            "user_id": user_id,
            "payment_method": "bkash",
            "amount": 999.00,
            "currency": "BDT",
            "status": "success",
            "verified_at": datetime.utcnow().isoformat()
        },
        {
            "transaction_id": "TXN_HIST_002",
            "user_id": user_id,
            "payment_method": "debit_card",
            "amount": 999.00,
            "currency": "BDT",
            "status": "failed",
            "verified_at": datetime.utcnow().isoformat()
        },
        {
            "transaction_id": "TXN_HIST_003",
            "user_id": user_id,
            "payment_method": "credit_card",
            "amount": 999.00,
            "currency": "BDT",
            "status": "pending"
        }
    ]
    
    for txn in transactions:
        supabase_service.client.table("transactions").insert(txn).execute()
    
    return transactions


def test_get_payment_history_success(test_user, test_transactions):
    """Test successful retrieval of payment history"""
    google_sub = test_user["google_sub"]
    
    # Get payment history
    response = client.get(f"/api/payments/history?user_id={google_sub}")
    
    assert response.status_code == 200
    data = response.json()
    
    # Verify response structure
    assert "transactions" in data
    assert "total_count" in data
    assert isinstance(data["transactions"], list)
    assert isinstance(data["total_count"], int)
    
    # Verify we got all transactions
    assert len(data["transactions"]) == 3
    assert data["total_count"] == 3
    
    # Verify transaction details are complete
    for txn in data["transactions"]:
        assert "transaction_id" in txn
        assert "payment_method" in txn
        assert "amount" in txn
        assert "currency" in txn
        assert "status" in txn
        assert "created_at" in txn
        # verified_at may be None for pending transactions
        
        # Verify status is valid
        assert txn["status"] in ["pending", "success", "failed"]
        
        # Verify payment method is valid
        assert txn["payment_method"] in ["bkash", "debit_card", "credit_card"]


def test_get_payment_history_with_pagination(test_user, test_transactions):
    """Test payment history with pagination parameters"""
    google_sub = test_user["google_sub"]
    
    # Get first 2 transactions
    response = client.get(f"/api/payments/history?user_id={google_sub}&limit=2&offset=0")
    
    assert response.status_code == 200
    data = response.json()
    
    assert len(data["transactions"]) == 2
    assert data["total_count"] == 3
    
    # Get next transaction
    response = client.get(f"/api/payments/history?user_id={google_sub}&limit=2&offset=2")
    
    assert response.status_code == 200
    data = response.json()
    
    assert len(data["transactions"]) == 1
    assert data["total_count"] == 3


def test_get_payment_history_ordered_by_date(test_user, test_transactions):
    """Test that transactions are ordered by created_at descending"""
    google_sub = test_user["google_sub"]
    
    response = client.get(f"/api/payments/history?user_id={google_sub}")
    
    assert response.status_code == 200
    data = response.json()
    
    # Verify transactions are ordered by created_at descending (newest first)
    transactions = data["transactions"]
    if len(transactions) > 1:
        for i in range(len(transactions) - 1):
            current_date = datetime.fromisoformat(transactions[i]["created_at"].replace('Z', '+00:00'))
            next_date = datetime.fromisoformat(transactions[i + 1]["created_at"].replace('Z', '+00:00'))
            assert current_date >= next_date, "Transactions should be ordered by created_at descending"


def test_get_payment_history_empty(test_user):
    """Test payment history for user with no transactions"""
    google_sub = test_user["google_sub"]
    
    response = client.get(f"/api/payments/history?user_id={google_sub}")
    
    assert response.status_code == 200
    data = response.json()
    
    assert data["transactions"] == []
    assert data["total_count"] == 0


def test_get_payment_history_user_not_found():
    """Test payment history for non-existent user"""
    response = client.get("/api/payments/history?user_id=nonexistent_user_12345")
    
    assert response.status_code == 404
    response_data = response.json()
    # Handle both error formats
    if "detail" in response_data:
        assert "not found" in response_data["detail"].lower()
    else:
        # Alternative error format
        assert response.status_code == 404


def test_get_payment_history_invalid_limit(test_user):
    """Test payment history with invalid limit parameter"""
    google_sub = test_user["google_sub"]
    
    # Test limit = 0
    response = client.get(f"/api/payments/history?user_id={google_sub}&limit=0")
    assert response.status_code == 400
    assert "limit" in response.json()["error"]["message"].lower()
    
    # Test limit > 100
    response = client.get(f"/api/payments/history?user_id={google_sub}&limit=101")
    assert response.status_code == 400
    assert "limit" in response.json()["error"]["message"].lower()
    
    # Test negative limit
    response = client.get(f"/api/payments/history?user_id={google_sub}&limit=-1")
    assert response.status_code == 400


def test_get_payment_history_invalid_offset(test_user):
    """Test payment history with invalid offset parameter"""
    google_sub = test_user["google_sub"]
    
    # Test negative offset
    response = client.get(f"/api/payments/history?user_id={google_sub}&offset=-1")
    assert response.status_code == 400
    assert "offset" in response.json()["error"]["message"].lower()


def test_get_payment_history_filters_by_user(test_user, test_transactions):
    """Test that payment history only returns transactions for the specified user"""
    supabase_service = get_supabase_service()
    
    # Create another user with transactions
    other_google_sub = f"test_other_user_{datetime.utcnow().timestamp()}"
    other_user_data = {
        "google_sub": other_google_sub,
        "email": f"{other_google_sub}@test.com",
        "name": "Other Test User",
        "subscription_status": "free"
    }
    
    other_user_response = supabase_service.client.table("users").insert(other_user_data).execute()
    other_user_id = other_user_response.data[0]["id"]
    
    # Create transaction for other user
    other_txn = {
        "transaction_id": "TXN_OTHER_001",
        "user_id": other_user_id,
        "payment_method": "bkash",
        "amount": 999.00,
        "currency": "BDT",
        "status": "success"
    }
    supabase_service.client.table("transactions").insert(other_txn).execute()
    
    try:
        # Get payment history for original test user
        google_sub = test_user["google_sub"]
        response = client.get(f"/api/payments/history?user_id={google_sub}")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify we only get transactions for the test user (3 transactions)
        assert len(data["transactions"]) == 3
        assert data["total_count"] == 3
        
        # Verify none of the transactions belong to the other user
        transaction_ids = [txn["transaction_id"] for txn in data["transactions"]]
        assert "TXN_OTHER_001" not in transaction_ids
        
    finally:
        # Cleanup other user
        supabase_service.client.table("transactions").delete().eq("user_id", other_user_id).execute()
        supabase_service.client.table("users").delete().eq("id", other_user_id).execute()


def test_get_payment_history_transaction_details_complete(test_user, test_transactions):
    """Test that all required transaction details are present (Requirements 6.2, 6.4)"""
    google_sub = test_user["google_sub"]
    
    response = client.get(f"/api/payments/history?user_id={google_sub}")
    
    assert response.status_code == 200
    data = response.json()
    
    # Verify each transaction has all required fields
    for txn in data["transactions"]:
        # Required fields from Requirements 6.2
        assert txn["transaction_id"] is not None
        assert txn["amount"] > 0
        assert txn["created_at"] is not None
        assert txn["status"] in ["pending", "success", "failed"]
        
        # Verify date format is valid
        created_at = datetime.fromisoformat(txn["created_at"].replace('Z', '+00:00'))
        assert isinstance(created_at, datetime)
        
        # Verify verified_at is present for completed transactions
        if txn["status"] in ["success", "failed"]:
            assert txn["verified_at"] is not None
            verified_at = datetime.fromisoformat(txn["verified_at"].replace('Z', '+00:00'))
            assert isinstance(verified_at, datetime)


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
