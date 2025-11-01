#!/usr/bin/env python3
"""
Test script to reproduce the empty token issue
"""
import os
import sys
from dotenv import load_dotenv
from app.services.encryption_service import get_encryption_service
from app.services.supabase_service import get_supabase_service

async def main():
    # Load environment variables
    load_dotenv()
    
    try:
        encryption_service = get_encryption_service()
        supabase_service = get_supabase_service()
        
        print("Testing empty token encryption...")
        
        # Test 1: Try to encrypt empty string
        try:
            result = encryption_service.encrypt("")
            print(f"Empty string encrypted to: '{result}'")
        except Exception as e:
            print(f"Empty string encryption failed: {e}")
        
        # Test 2: Try to encrypt None (this will fail)
        try:
            result = encryption_service.encrypt(None)
            print(f"None encrypted to: '{result}'")
        except Exception as e:
            print(f"None encryption failed: {e}")
        
        # Test 3: Try to encrypt whitespace
        try:
            result = encryption_service.encrypt("   ")
            print(f"Whitespace encrypted to: '{result}'")
        except Exception as e:
            print(f"Whitespace encryption failed: {e}")
        
        print("\nTesting what happens when frontend sends empty access token...")
        
        # Simulate what happens when frontend sends empty access token
        test_user_id = "test-user-123"
        test_email = "test@example.com"
        
        # Create test user
        user = await supabase_service.get_or_create_user(
            google_sub=test_user_id,
            email=test_email,
            name="Test User"
        )
        
        print(f"Created test user: {user['id']}")
        
        # Try to store empty access token (this should fail now)
        try:
            encrypted_token = encryption_service.encrypt("")
            await supabase_service.store_encrypted_token(
                user_id=user["id"],
                token_type="access_token",
                encrypted_token=encrypted_token
            )
            print("Empty token stored successfully (this shouldn't happen)")
        except Exception as e:
            print(f"Empty token storage failed as expected: {e}")
        
        # Clean up test user
        supabase_service.client.table("users").delete().eq("google_sub", test_user_id).execute()
        print("Cleaned up test user")
        
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())