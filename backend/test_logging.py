"""Test script to verify logging and error handling"""
import requests
import json

BASE_URL = "http://localhost:8000"

def test_endpoint(name, url, expected_status=200):
    """Test an endpoint and print results"""
    print(f"\n{'='*60}")
    print(f"Testing: {name}")
    print(f"URL: {url}")
    print(f"{'='*60}")
    
    try:
        response = requests.get(url)
        print(f"Status Code: {response.status_code}")
        print(f"Request ID: {response.headers.get('x-request-id', 'N/A')}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        if response.status_code == expected_status:
            print("✓ Test passed!")
        else:
            print(f"✗ Test failed! Expected {expected_status}, got {response.status_code}")
            
    except requests.exceptions.RequestException as e:
        print(f"✗ Request failed: {e}")
    except json.JSONDecodeError:
        print(f"Response (not JSON): {response.text}")

if __name__ == "__main__":
    print("ScholarMate Backend - Logging & Error Handling Tests")
    print("="*60)
    
    # Test successful requests
    test_endpoint("Health Check", f"{BASE_URL}/api/health", 200)
    test_endpoint("Root Endpoint", f"{BASE_URL}/", 200)
    test_endpoint("Test Success", f"{BASE_URL}/api/test/success", 200)
    
    # Test error handling
    test_endpoint("400 Error", f"{BASE_URL}/api/test/error-400", 400)
    test_endpoint("500 Error", f"{BASE_URL}/api/test/error-500", 500)
    
    print("\n" + "="*60)
    print("All tests completed!")
    print("Check the backend logs for structured logging output")
    print("="*60)
