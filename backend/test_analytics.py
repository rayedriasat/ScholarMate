#!/usr/bin/env python3
"""Test analytics API endpoints"""
import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8000"

def test_analytics_sync():
    """Test syncing analytics data"""
    print("🧪 Testing analytics sync...")
    
    # Sample analytics data
    sync_data = {
        "sessions": [
            {
                "id": "test-session-1",
                "file_id": "test-file-123",
                "file_name": "Test Document.pdf",
                "start_time": datetime.now().isoformat(),
                "end_time": datetime.now().isoformat(),
                "duration_seconds": 300,
                "pages_read": 10,
                "total_pages": 50
            }
        ],
        "page_reads": [
            {
                "id": "test-file-123_1",
                "file_id": "test-file-123",
                "page_number": 1,
                "first_read_at": datetime.now().isoformat(),
                "last_read_at": datetime.now().isoformat(),
                "read_count": 1
            },
            {
                "id": "test-file-123_2",
                "file_id": "test-file-123",
                "page_number": 2,
                "first_read_at": datetime.now().isoformat(),
                "last_read_at": datetime.now().isoformat(),
                "read_count": 2
            }
        ]
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/analytics/sync",
            json=sync_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Sync successful: {result}")
            return True
        else:
            print(f"❌ Sync failed: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_get_sessions():
    """Test getting reading sessions"""
    print("\n🧪 Testing get sessions...")
    
    try:
        response = requests.get(f"{BASE_URL}/api/analytics/sessions?limit=10")
        
        if response.status_code == 200:
            sessions = response.json()
            print(f"✅ Retrieved {len(sessions)} sessions")
            if sessions:
                print(f"   Sample: {sessions[0]}")
            return True
        else:
            print(f"❌ Failed: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def test_get_stats():
    """Test getting analytics stats"""
    print("\n🧪 Testing get stats...")
    
    try:
        response = requests.get(f"{BASE_URL}/api/analytics/stats")
        
        if response.status_code == 200:
            stats = response.json()
            print(f"✅ Stats retrieved:")
            print(f"   Total reading time: {stats['total_reading_time']}s")
            print(f"   Total pages read: {stats['total_pages_read']}")
            print(f"   Reading streak: {stats['reading_streak']} days")
            print(f"   Files read: {stats['files_read']}")
            return True
        else:
            print(f"❌ Failed: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    print("=" * 60)
    print("Analytics API Test Suite")
    print("=" * 60)
    print(f"Testing against: {BASE_URL}")
    print()
    
    # Note: These tests require authentication in production
    # For now, they test the endpoint structure
    
    results = []
    results.append(("Sync Analytics", test_analytics_sync()))
    results.append(("Get Sessions", test_get_sessions()))
    results.append(("Get Stats", test_get_stats()))
    
    print("\n" + "=" * 60)
    print("Test Results Summary")
    print("=" * 60)
    
    for test_name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    total = len(results)
    passed = sum(1 for _, p in results if p)
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed!")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed")

if __name__ == "__main__":
    main()
