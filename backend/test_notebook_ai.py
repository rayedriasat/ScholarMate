"""
Test script for Notebook AI endpoints
Run this to verify the backend is working correctly
"""

import requests
import json
import sys

BASE_URL = "http://localhost:8000"

def test_health():
    """Test if backend is running"""
    print("🔵 Testing backend health...")
    try:
        response = requests.get(f"{BASE_URL}/api/health", timeout=5)
        if response.status_code == 200:
            print("✅ Backend is running")
            return True
        else:
            print(f"❌ Backend returned status {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to backend. Is it running?")
        print("   Run: uv run python run.py")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_quiz_endpoint():
    """Test quiz generation endpoint"""
    print("\n🔵 Testing quiz generation endpoint...")
    
    payload = {
        "user_id": "test-user-123",
        "file_ids": ["test-file-1"],
        "num_questions": 2,
        "difficulty": "medium"
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/notebook-ai/generate-quiz",
            json=payload,
            timeout=60
        )
        
        if response.status_code == 200:
            data = response.json()
            if 'questions' in data:
                print(f"✅ Quiz endpoint working - Generated {len(data['questions'])} questions")
                return True
            else:
                print("❌ Response missing 'questions' field")
                print(f"   Response: {data}")
                return False
        else:
            print(f"❌ Quiz endpoint returned status {response.status_code}")
            print(f"   Error: {response.text}")
            return False
            
    except requests.exceptions.Timeout:
        print("❌ Request timed out (>60s)")
        print("   This might be normal if files aren't indexed")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_summary_endpoint():
    """Test summary generation endpoint"""
    print("\n🔵 Testing summary generation endpoint...")
    
    payload = {
        "user_id": "test-user-123",
        "file_ids": ["test-file-1"],
        "length": "medium"
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/notebook-ai/generate-summary",
            json=payload,
            timeout=60
        )
        
        if response.status_code == 200:
            data = response.json()
            if 'summary' in data and 'key_points' in data:
                print("✅ Summary endpoint working")
                return True
            else:
                print("❌ Response missing required fields")
                print(f"   Response: {data}")
                return False
        else:
            print(f"❌ Summary endpoint returned status {response.status_code}")
            print(f"   Error: {response.text}")
            return False
            
    except requests.exceptions.Timeout:
        print("❌ Request timed out (>60s)")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_flashcards_endpoint():
    """Test flashcards generation endpoint"""
    print("\n🔵 Testing flashcards generation endpoint...")
    
    payload = {
        "user_id": "test-user-123",
        "file_ids": ["test-file-1"],
        "num_cards": 5
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/notebook-ai/generate-flashcards",
            json=payload,
            timeout=60
        )
        
        if response.status_code == 200:
            data = response.json()
            if 'flashcards' in data:
                print(f"✅ Flashcards endpoint working - Generated {len(data['flashcards'])} cards")
                return True
            else:
                print("❌ Response missing 'flashcards' field")
                print(f"   Response: {data}")
                return False
        else:
            print(f"❌ Flashcards endpoint returned status {response.status_code}")
            print(f"   Error: {response.text}")
            return False
            
    except requests.exceptions.Timeout:
        print("❌ Request timed out (>60s)")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    """Run all tests"""
    print("=" * 60)
    print("Notebook AI Endpoints Test")
    print("=" * 60)
    
    results = []
    
    # Test 1: Health check
    results.append(("Health Check", test_health()))
    
    if not results[0][1]:
        print("\n❌ Backend not running. Cannot continue tests.")
        print("\nTo start backend:")
        print("  cd backend")
        print("  uv run python run.py")
        sys.exit(1)
    
    # Test 2: Quiz endpoint
    results.append(("Quiz Endpoint", test_quiz_endpoint()))
    
    # Test 3: Summary endpoint
    results.append(("Summary Endpoint", test_summary_endpoint()))
    
    # Test 4: Flashcards endpoint
    results.append(("Flashcards Endpoint", test_flashcards_endpoint()))
    
    # Summary
    print("\n" + "=" * 60)
    print("Test Summary")
    print("=" * 60)
    
    for name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} - {name}")
    
    total = len(results)
    passed = sum(1 for _, p in results if p)
    
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed! Backend is working correctly.")
        return 0
    else:
        print("\n⚠️  Some tests failed. Check errors above.")
        print("\nCommon issues:")
        print("  1. Files not indexed - Endpoints will fail without indexed files")
        print("  2. API key not configured - Check backend/.env")
        print("  3. Pinecone not configured - Check PINECONE_API_KEY")
        print("  4. GROQ key missing - Check GROQ_API_KEY")
        return 1

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\n⚠️  Tests interrupted by user")
        sys.exit(1)
