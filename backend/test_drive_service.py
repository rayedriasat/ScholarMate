"""
Test script for Backend Drive Service.
Tests fetching files from Google Drive using encrypted user tokens.

Note: This test requires a user to have authenticated and stored tokens in the database.
"""

import asyncio
import sys
import os

# Add app directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from app.services.drive_service import get_drive_service
from app.services.supabase_service import get_supabase_service


async def test_token_refresh():
    """Test token refresh functionality."""
    print("=" * 60)
    print("Testing Backend Drive Service - Token Refresh")
    print("=" * 60)
    
    drive_service = get_drive_service()
    supabase_service = get_supabase_service()
    
    # Get a test user from database
    print("\n[Test 1] Finding a test user with stored tokens...")
    response = supabase_service.client.table("users").select("*").limit(1).execute()
    
    if not response.data or len(response.data) == 0:
        print("⚠️  No users found in database. Please authenticate via the app first.")
        return False
    
    user = response.data[0]
    user_id = user["id"]
    print(f"✓ Found test user: {user['email']} (ID: {user_id})")
    
    # Check if user has refresh token
    print("\n[Test 2] Checking for refresh token...")
    encrypted_refresh_token = await supabase_service.get_encrypted_token(
        user_id=user_id,
        token_type="refresh_token"
    )
    
    if not encrypted_refresh_token:
        print("⚠️  No refresh token found for user. Please authenticate via the app first.")
        return False
    
    print("✓ Refresh token found")
    
    # Test token refresh
    print("\n[Test 3] Refreshing access token...")
    try:
        access_token = await drive_service.refresh_access_token(user_id)
        print(f"✓ Successfully refreshed access token (length: {len(access_token)})")
        print(f"  Token preview: {access_token[:20]}...")
        return True
    except Exception as e:
        print(f"❌ Failed to refresh token: {str(e)}")
        return False


async def test_file_fetch():
    """Test fetching a file from Google Drive."""
    print("\n" + "=" * 60)
    print("Testing Backend Drive Service - File Fetch")
    print("=" * 60)
    
    drive_service = get_drive_service()
    supabase_service = get_supabase_service()
    
    # Get a test user
    print("\n[Test 1] Finding a test user...")
    response = supabase_service.client.table("users").select("*").limit(1).execute()
    
    if not response.data or len(response.data) == 0:
        print("⚠️  No users found in database.")
        return False
    
    user = response.data[0]
    user_id = user["id"]
    print(f"✓ Found test user: {user['email']}")
    
    # Get a file from the user's files
    print("\n[Test 2] Finding a test file...")
    files_response = supabase_service.client.table("files").select("*").eq("user_id", user_id).limit(1).execute()
    
    if not files_response.data or len(files_response.data) == 0:
        print("⚠️  No files found for user. Please upload a file via the app first.")
        print("   Skipping file fetch test.")
        return True  # Not a failure, just no data to test with
    
    file_record = files_response.data[0]
    drive_file_id = file_record["drive_file_id"]
    file_name = file_record["name"]
    print(f"✓ Found test file: {file_name} (Drive ID: {drive_file_id})")
    
    # Test file metadata fetch
    print("\n[Test 3] Fetching file metadata from Google Drive...")
    try:
        metadata = await drive_service.get_file_metadata(drive_file_id, user_id)
        print(f"✓ Successfully fetched metadata:")
        print(f"  Name: {metadata.get('name')}")
        print(f"  MIME Type: {metadata.get('mimeType')}")
        print(f"  Size: {metadata.get('size')} bytes")
    except Exception as e:
        print(f"❌ Failed to fetch metadata: {str(e)}")
        return False
    
    # Test file bytes fetch (only for small files)
    file_size = int(metadata.get('size', 0))
    if file_size > 0 and file_size < 1024 * 1024:  # Less than 1MB
        print("\n[Test 4] Fetching file bytes from Google Drive...")
        try:
            file_bytes = await drive_service.get_file_bytes(drive_file_id, user_id)
            print(f"✓ Successfully fetched file bytes: {len(file_bytes)} bytes")
            return True
        except Exception as e:
            print(f"❌ Failed to fetch file bytes: {str(e)}")
            return False
    else:
        print(f"\n[Test 4] Skipping file bytes fetch (file too large: {file_size} bytes)")
        return True


async def test_integration():
    """Run integration tests for Drive service."""
    print("\n🚀 Starting Backend Drive Service Tests\n")
    
    # Test token refresh
    token_test_passed = await test_token_refresh()
    
    # Test file fetch
    file_test_passed = await test_file_fetch()
    
    if token_test_passed and file_test_passed:
        print("\n" + "=" * 60)
        print("✅ All Backend Drive Service tests passed!")
        print("=" * 60)
        return True
    else:
        print("\n" + "=" * 60)
        print("⚠️  Some tests were skipped or failed.")
        print("   Make sure to authenticate and upload files via the app first.")
        print("=" * 60)
        return False


if __name__ == "__main__":
    try:
        # Load environment variables
        from dotenv import load_dotenv
        load_dotenv()
        
        # Run tests
        success = asyncio.run(test_integration())
        
        if not success:
            print("\n💡 To run full tests:")
            print("   1. Open the ScholarMate app")
            print("   2. Sign in with Google")
            print("   3. Upload a small PDF file")
            print("   4. Run this test again\n")
        
    except Exception as e:
        print(f"\n❌ Test failed with error: {str(e)}\n")
        import traceback
        traceback.print_exc()
        sys.exit(1)
