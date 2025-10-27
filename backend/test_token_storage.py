#!/usr/bin/env python3
"""
Test script for database connection and token storage
Run with: uv run python backend/test_token_storage.py
"""
import asyncio
import sys
from pathlib import Path

# Add backend to path
sys.path.insert(0, str(Path(__file__).parent))

from app.services.supabase_service import get_supabase_service
from app.services.encryption_service import get_encryption_service
from app.utils.logging_config import setup_logging, get_logger

# Setup logging
setup_logging("INFO")
logger = get_logger(__name__)


async def test_database_connection():
    """Test basic database connection"""
    logger.info("Testing database connection...")
    
    try:
        service = get_supabase_service()
        logger.info("✅ Successfully connected to Supabase")
        return True
    except Exception as e:
        logger.error(f"❌ Failed to connect to Supabase: {e}")
        return False


async def test_encryption_service():
    """Test encryption and decryption"""
    logger.info("Testing encryption service...")
    
    try:
        service = get_encryption_service()
        
        # Test data
        test_string = "test_access_token_12345"
        
        # Encrypt
        encrypted = service.encrypt(test_string)
        logger.info(f"✅ Encrypted test string: {encrypted[:50]}...")
        
        # Decrypt
        decrypted = service.decrypt(encrypted)
        
        if decrypted == test_string:
            logger.info("✅ Decryption successful - matches original")
            return True
        else:
            logger.error("❌ Decryption failed - doesn't match original")
            return False
            
    except Exception as e:
        logger.error(f"❌ Encryption test failed: {e}")
        return False


async def test_user_creation():
    """Test user creation or retrieval"""
    logger.info("Testing user creation...")
    
    try:
        service = get_supabase_service()
        
        # Test user data
        test_google_sub = "test_google_sub_12345"
        test_email = "test@example.com"
        test_name = "Test User"
        
        # Create or get user
        user = await service.get_or_create_user(
            google_sub=test_google_sub,
            email=test_email,
            name=test_name
        )
        
        logger.info(f"✅ User created/retrieved: {user['id']}")
        logger.info(f"   Email: {user['email']}")
        logger.info(f"   Name: {user['name']}")
        
        return user
        
    except Exception as e:
        logger.error(f"❌ User creation test failed: {e}")
        return None


async def test_token_storage(user_id: str):
    """Test token storage and retrieval"""
    logger.info("Testing token storage...")
    
    try:
        supabase_service = get_supabase_service()
        encryption_service = get_encryption_service()
        
        # Test token
        test_token = "test_access_token_abcdef123456"
        
        # Encrypt token
        encrypted_token = encryption_service.encrypt(test_token)
        logger.info(f"✅ Token encrypted: {encrypted_token[:50]}...")
        
        # Store token
        stored = await supabase_service.store_encrypted_token(
            user_id=user_id,
            token_type="access_token",
            encrypted_token=encrypted_token
        )
        logger.info(f"✅ Token stored in database: {stored['id']}")
        
        # Retrieve token
        retrieved_encrypted = await supabase_service.get_encrypted_token(
            user_id=user_id,
            token_type="access_token"
        )
        
        if not retrieved_encrypted:
            logger.error("❌ Failed to retrieve token from database")
            return False
        
        logger.info("✅ Token retrieved from database")
        
        # Decrypt token
        decrypted_token = encryption_service.decrypt(retrieved_encrypted)
        
        if decrypted_token == test_token:
            logger.info("✅ Token decryption successful - matches original")
            return True
        else:
            logger.error("❌ Token decryption failed - doesn't match original")
            return False
            
    except Exception as e:
        logger.error(f"❌ Token storage test failed: {e}")
        return False


async def test_token_cleanup(user_id: str):
    """Clean up test data"""
    logger.info("Cleaning up test data...")
    
    try:
        service = get_supabase_service()
        
        # Delete test tokens
        await service.delete_user_tokens(user_id)
        logger.info("✅ Test tokens deleted")
        
        # Note: We don't delete the test user to avoid issues with foreign keys
        # In a real scenario, you might want to delete the user too
        logger.info("ℹ️  Test user left in database (can be deleted manually)")
        
        return True
        
    except Exception as e:
        logger.error(f"❌ Cleanup failed: {e}")
        return False


async def main():
    """Run all tests"""
    logger.info("=" * 60)
    logger.info("ScholarMate Database & Token Storage Tests")
    logger.info("=" * 60)
    
    results = []
    
    # Test 1: Database connection
    logger.info("\n[Test 1/5] Database Connection")
    logger.info("-" * 60)
    result = await test_database_connection()
    results.append(("Database Connection", result))
    
    if not result:
        logger.error("\n❌ Database connection failed. Cannot continue tests.")
        logger.error("Please check your SUPABASE_URL and SUPABASE_SERVICE_KEY in .env")
        return
    
    # Test 2: Encryption service
    logger.info("\n[Test 2/5] Encryption Service")
    logger.info("-" * 60)
    result = await test_encryption_service()
    results.append(("Encryption Service", result))
    
    if not result:
        logger.error("\n❌ Encryption service failed. Cannot continue tests.")
        return
    
    # Test 3: User creation
    logger.info("\n[Test 3/5] User Creation")
    logger.info("-" * 60)
    user = await test_user_creation()
    results.append(("User Creation", user is not None))
    
    if not user:
        logger.error("\n❌ User creation failed. Cannot continue tests.")
        return
    
    user_id = user['id']
    
    # Test 4: Token storage
    logger.info("\n[Test 4/5] Token Storage & Retrieval")
    logger.info("-" * 60)
    result = await test_token_storage(user_id)
    results.append(("Token Storage", result))
    
    # Test 5: Cleanup
    logger.info("\n[Test 5/5] Cleanup")
    logger.info("-" * 60)
    result = await test_token_cleanup(user_id)
    results.append(("Cleanup", result))
    
    # Summary
    logger.info("\n" + "=" * 60)
    logger.info("Test Summary")
    logger.info("=" * 60)
    
    for test_name, passed in results:
        status = "✅ PASS" if passed else "❌ FAIL"
        logger.info(f"{status} - {test_name}")
    
    all_passed = all(result for _, result in results)
    
    if all_passed:
        logger.info("\n🎉 All tests passed!")
        logger.info("\nNext steps:")
        logger.info("1. ✅ Database schema is set up correctly")
        logger.info("2. ✅ Encryption is working")
        logger.info("3. ✅ Token storage and retrieval is working")
        logger.info("4. ⏭️  Ready to implement file metadata sync")
    else:
        logger.error("\n❌ Some tests failed. Please review the errors above.")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())
