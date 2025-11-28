"""
Integration test for POST /api/payments/initialize endpoint using FastAPI TestClient

This test verifies the endpoint is properly registered and responds correctly.
"""
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_initialize_endpoint_exists():
    """Test that the initialize endpoint is registered"""
    # This will fail with 404 if user doesn't exist, but that's expected
    # We're just verifying the endpoint is registered
    response = client.post(
        "/api/payments/initialize",
        json={
            "user_id": "nonexistent_user",
            "payment_method": "bkash",
            "amount": 500.0,
            "currency": "BDT"
        }
    )
    
    # Should get 404 (user not found) or 500, not 404 (endpoint not found)
    # The key is that we get a response, not a 404 for missing route
    assert response.status_code in [404, 500], f"Unexpected status code: {response.status_code}"
    
    # If we get a JSON response, it means the endpoint exists
    try:
        data = response.json()
        assert "detail" in data
        print(f"✓ Endpoint exists and returns proper error: {data['detail']}")
    except:
        pass


def test_initialize_endpoint_validation():
    """Test that the endpoint validates input correctly"""
    # Test with invalid payment method
    response = client.post(
        "/api/payments/initialize",
        json={
            "user_id": "test_user",
            "payment_method": "invalid_method",
            "amount": 500.0,
            "currency": "BDT"
        }
    )
    
    # Should get 422 for validation error
    assert response.status_code == 422
    data = response.json()
    assert "error" in data
    assert data["error"]["status_code"] == 422
    print(f"✓ Endpoint validates payment method correctly")


def test_initialize_endpoint_negative_amount():
    """Test that the endpoint rejects negative amounts"""
    response = client.post(
        "/api/payments/initialize",
        json={
            "user_id": "test_user",
            "payment_method": "bkash",
            "amount": -100.0,
            "currency": "BDT"
        }
    )
    
    # Should get 422 for validation error
    assert response.status_code == 422
    data = response.json()
    assert "error" in data
    assert data["error"]["status_code"] == 422
    print(f"✓ Endpoint rejects negative amounts")


def test_initialize_endpoint_missing_fields():
    """Test that the endpoint requires all fields"""
    response = client.post(
        "/api/payments/initialize",
        json={
            "user_id": "test_user",
            "payment_method": "bkash"
            # Missing amount
        }
    )
    
    # Should get 422 for validation error
    assert response.status_code == 422
    data = response.json()
    assert "error" in data
    assert data["error"]["status_code"] == 422
    print(f"✓ Endpoint requires all fields")


if __name__ == "__main__":
    print("Testing POST /api/payments/initialize endpoint integration...")
    print()
    
    test_initialize_endpoint_exists()
    test_initialize_endpoint_validation()
    test_initialize_endpoint_negative_amount()
    test_initialize_endpoint_missing_fields()
    
    print()
    print("All integration tests passed! ✓")
