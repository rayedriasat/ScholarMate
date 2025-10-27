"""
Test script for annotation synchronization endpoints

This script tests the annotation sync API endpoints to ensure they work correctly.
Run this after starting the backend server.
"""
import requests
import json
from uuid import uuid4

# Configuration
BASE_URL = "http://localhost:8000"
TEST_USER_ID = str(uuid4())
TEST_FILE_ID = str(uuid4())


def test_create_annotation():
    """Test creating a new annotation"""
    print("\n=== Testing Create Annotation ===")
    
    annotation_data = {
        "file_id": TEST_FILE_ID,
        "annotation_type": "highlight",
        "page_number": 1,
        "position_data": {
            "left": 100.0,
            "top": 200.0,
            "right": 300.0,
            "bottom": 250.0
        },
        "content": "Test highlight annotation",
        "color": "#FFFF00"
    }
    
    response = requests.post(
        f"{BASE_URL}/api/annotations/?user_id={TEST_USER_ID}",
        json=annotation_data,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    if response.status_code == 201:
        print("✓ Annotation created successfully")
        return response.json()["id"]
    else:
        print("✗ Failed to create annotation")
        return None


def test_get_annotations(file_id):
    """Test getting annotations for a file"""
    print("\n=== Testing Get Annotations ===")
    
    response = requests.get(
        f"{BASE_URL}/api/annotations/{file_id}?user_id={TEST_USER_ID}",
        headers={"Content-Type": "application/json"}
    )
    
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    if response.status_code == 200:
        print("✓ Annotations retrieved successfully")
        return True
    else:
        print("✗ Failed to get annotations")
        return False


def test_update_annotation(annotation_id):
    """Test updating an annotation"""
    print("\n=== Testing Update Annotation ===")
    
    update_data = {
        "content": "Updated annotation content",
        "color": "#FF0000"
    }
    
    response = requests.put(
        f"{BASE_URL}/api/annotations/{annotation_id}?user_id={TEST_USER_ID}",
        json=update_data,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    if response.status_code == 200:
        print("✓ Annotation updated successfully")
        return True
    else:
        print("✗ Failed to update annotation")
        return False


def test_sync_annotations():
    """Test bulk annotation sync"""
    print("\n=== Testing Bulk Annotation Sync ===")
    
    sync_data = {
        "annotations": [
            {
                "file_id": TEST_FILE_ID,
                "annotation_type": "underline",
                "page_number": 2,
                "position_data": {
                    "left": 150.0,
                    "top": 300.0,
                    "right": 400.0,
                    "bottom": 320.0
                },
                "content": "Underlined text",
                "color": "#00FF00"
            },
            {
                "file_id": TEST_FILE_ID,
                "annotation_type": "strikethrough",
                "page_number": 3,
                "position_data": {
                    "left": 200.0,
                    "top": 400.0,
                    "right": 500.0,
                    "bottom": 420.0
                },
                "content": "Strikethrough text",
                "color": "#0000FF"
            }
        ]
    }
    
    response = requests.post(
        f"{BASE_URL}/api/annotations/sync?user_id={TEST_USER_ID}&file_id={TEST_FILE_ID}",
        json=sync_data,
        headers={"Content-Type": "application/json"}
    )
    
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    
    if response.status_code == 200:
        print("✓ Annotations synced successfully")
        return True
    else:
        print("✗ Failed to sync annotations")
        return False


def test_delete_annotation(annotation_id):
    """Test deleting an annotation"""
    print("\n=== Testing Delete Annotation ===")
    
    response = requests.delete(
        f"{BASE_URL}/api/annotations/{annotation_id}?user_id={TEST_USER_ID}",
        headers={"Content-Type": "application/json"}
    )
    
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 204:
        print("✓ Annotation deleted successfully")
        return True
    else:
        print("✗ Failed to delete annotation")
        return False


def main():
    """Run all tests"""
    print("=" * 60)
    print("Annotation Synchronization API Tests")
    print("=" * 60)
    print(f"Base URL: {BASE_URL}")
    print(f"Test User ID: {TEST_USER_ID}")
    print(f"Test File ID: {TEST_FILE_ID}")
    
    try:
        # Test 1: Create annotation
        annotation_id = test_create_annotation()
        if not annotation_id:
            print("\n✗ Tests failed at create annotation")
            return
        
        # Test 2: Get annotations
        if not test_get_annotations(TEST_FILE_ID):
            print("\n✗ Tests failed at get annotations")
            return
        
        # Test 3: Update annotation
        if not test_update_annotation(annotation_id):
            print("\n✗ Tests failed at update annotation")
            return
        
        # Test 4: Bulk sync
        if not test_sync_annotations():
            print("\n✗ Tests failed at bulk sync")
            return
        
        # Test 5: Get annotations again to verify sync
        if not test_get_annotations(TEST_FILE_ID):
            print("\n✗ Tests failed at get annotations after sync")
            return
        
        # Test 6: Delete annotation
        if not test_delete_annotation(annotation_id):
            print("\n✗ Tests failed at delete annotation")
            return
        
        print("\n" + "=" * 60)
        print("✓ All tests passed successfully!")
        print("=" * 60)
        
    except requests.exceptions.ConnectionError:
        print("\n✗ Error: Could not connect to backend server")
        print("Make sure the backend is running at", BASE_URL)
    except Exception as e:
        print(f"\n✗ Error during tests: {e}")


if __name__ == "__main__":
    main()
