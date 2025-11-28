"""
Test suite for GET /api/payments/subscription-status endpoint

This test validates:
- Endpoint accepts user_id parameter
- Queries subscription service for current status
- Returns plan type, activation date, and expiry date
- Handles user not found errors
- Handles database errors gracefully

Requirements: 1.2, 5.1
"""

import pytest
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
from app.main import app
from app.services.supabase_service import get_supabase_service

client = TestClient(app)


@pytest.fixture
def test_user_google_sub():
    """Create a test user and return their google_sub"""
    supabase_service = get_supabase_service()
    
    # Create test user
    test_google_sub = f"test_sub_status_{datetime.utcnow().timestamp()}"
    user_data = {
        "google_sub": test_google_sub,
        "email": f"test_status_{datetime.utcnow().timestamp()}@example.com",
        "name": "Test Status User",
        "subscription_status": "free"
    }
    
    response = supabase_service.client.table("users").insert(user_data).execute()
    user_id = response.data[0]["id"]
    
    yield test_google_sub, user_id
    
    # Cleanup
    try:
        supabase_service.client.table("users").delete().eq("id", user_id).execute()
    except:
        pass


@pytest.fixture
def test_premium_user():
    """Create a test user with premium subscription"""
    supabase_service = get_supabase_service()
    
    # Create test user with premium status
    from datetime import timezone
    test_google_sub = f"test_sub_premium_{datetime.now(timezone.utc).timestamp()}"
    activated_at = datetime.now(timezone.utc)
    expires_at = activated_at + timedelta(days=365)
    
    user_data = {
        "google_sub": test_google_sub,
        "email": f"test_premium_{datetime.now(timezone.utc).timestamp()}@example.com",
        "name": "Test Premium User",
        "subscription_status": "premium",
        "subscription_activated_at": activated_at.isoformat(),
        "subscription_expires_at": expires_at.isoformat()
    }
    
    response = supabase_service.client.table("users").insert(user_data).execute()
    user_id = response.data[0]["id"]
    
    yield test_google_sub, user_id, activated_at, expires_at
    
    # Cleanup
    try:
        supabase_service.client.table("users").delete().eq("id", user_id).execute()
    except:
        pass


def test_get_subscription_status_free_user(test_user_google_sub):
    """Test getting subscription status for a free user"""
    google_sub, user_id = test_user_google_sub
    
    # Call endpoint
    response = client.get(
        "/api/payments/subscription-status",
        params={"user_id": google_sub}
    )
    
    # Verify response
    assert response.status_code == 200
    data = response.json()
    
    # Verify response structure
    assert "plan" in data
    assert "activated_at" in data
    assert "expires_at" in data
    assert "is_active" in data
    
    # Verify free user data
    assert data["plan"] == "free"
    assert data["activated_at"] is None
    assert data["expires_at"] is None
    assert data["is_active"] is False


def test_get_subscription_status_premium_user(test_premium_user):
    """Test getting subscription status for a premium user"""
    google_sub, user_id, activated_at, expires_at = test_premium_user
    
    # Call endpoint
    response = client.get(
        "/api/payments/subscription-status",
        params={"user_id": google_sub}
    )
    
    # Verify response
    assert response.status_code == 200
    data = response.json()
    
    # Verify response structure
    assert "plan" in data
    assert "activated_at" in data
    assert "expires_at" in data
    assert "is_active" in data
    
    # Verify premium user data
    assert data["plan"] == "premium"
    assert data["activated_at"] is not None
    assert data["expires_at"] is not None
    assert data["is_active"] is True
    
    # Verify timestamps are close to expected values (within 1 second)
    response_activated = datetime.fromisoformat(data["activated_at"].replace('Z', '+00:00'))
    response_expires = datetime.fromisoformat(data["expires_at"].replace('Z', '+00:00'))
    
    assert abs((response_activated - activated_at).total_seconds()) < 1
    assert abs((response_expires - expires_at).total_seconds()) < 1


def test_get_subscription_status_user_not_found():
    """Test getting subscription status for non-existent user"""
    # Call endpoint with non-existent user
    response = client.get(
        "/api/payments/subscription-status",
        params={"user_id": "nonexistent_user_12345"}
    )
    
    # Verify 404 response
    assert response.status_code == 404
    data = response.json()
    assert "error" in data
    assert "not found" in data["error"]["message"].lower()


def test_get_subscription_status_missing_user_id():
    """Test endpoint requires user_id parameter"""
    # Call endpoint without user_id
    response = client.get("/api/payments/subscription-status")
    
    # Verify 422 validation error
    assert response.status_code == 422


def test_get_subscription_status_expired_premium(test_user_google_sub):
    """Test getting subscription status for expired premium user"""
    google_sub, user_id = test_user_google_sub
    supabase_service = get_supabase_service()
    
    # Update user to have expired premium subscription
    activated_at = datetime.utcnow() - timedelta(days=400)
    expires_at = datetime.utcnow() - timedelta(days=35)  # Expired 35 days ago
    
    update_data = {
        "subscription_status": "premium",
        "subscription_activated_at": activated_at.isoformat(),
        "subscription_expires_at": expires_at.isoformat()
    }
    
    supabase_service.client.table("users").update(update_data).eq("id", user_id).execute()
    
    # Call endpoint
    response = client.get(
        "/api/payments/subscription-status",
        params={"user_id": google_sub}
    )
    
    # Verify response
    assert response.status_code == 200
    data = response.json()
    
    # Verify expired premium shows as inactive
    assert data["plan"] == "premium"
    assert data["activated_at"] is not None
    assert data["expires_at"] is not None
    assert data["is_active"] is False  # Should be inactive due to expiry


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
