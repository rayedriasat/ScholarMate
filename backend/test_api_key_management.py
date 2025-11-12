"""
Test script for API Key Management system.
Run with: uv run python test_api_key_management.py
"""

import asyncio
import os
from dotenv import load_dotenv

# Load environment
load_dotenv()

from app.services.api_key_service import get_api_key_service
from app.services.provider_service import ProviderFactory
from app.services.encryption_service import get_encryption_service


async def test_encryption():
    """Test encryption service."""
    print("\n=== Testing Encryption Service ===")
    
    encryption_service = get_encryption_service()
    
    test_key = "sk-test-key-12345"
    encrypted = encryption_service.encrypt(test_key)
    decrypted = encryption_service.decrypt(encrypted)
    
    print(f"Original: {test_key}")
    print(f"Encrypted: {encrypted[:50]}...")
    print(f"Decrypted: {decrypted}")
    print(f"✅ Encryption works: {test_key == decrypted}")


async def test_provider_factory():
    """Test provider factory."""
    print("\n=== Testing Provider Factory ===")
    
    # List supported providers
    providers = ProviderFactory.get_supported_providers()
    print(f"Supported providers: {len(providers)}")
    for p in providers:
        print(f"  - {p['name']}: {p['display_name']} (chat: {p['supports_chat']})")
    
    # Test GROQ provider creation
    groq_key = os.getenv("GROQ_API_KEY")
    if groq_key:
        print("\n✅ Testing GROQ provider...")
        provider = ProviderFactory.create_provider("groq", groq_key)
        print(f"  Provider name: {provider.get_provider_name()}")
        
        # Test validation
        result = await provider.validate_key()
        print(f"  Validation: {result['is_valid']}")
        if result['is_valid']:
            print(f"  Model info: {result.get('model_info')}")
    else:
        print("⚠️  GROQ_API_KEY not set, skipping provider test")


async def test_api_key_service():
    """Test API key service (requires Supabase connection)."""
    print("\n=== Testing API Key Service ===")
    
    try:
        api_key_service = get_api_key_service()
        
        # Test with a dummy user ID (won't actually save without valid user)
        test_user_id = "00000000-0000-0000-0000-000000000000"
        
        print("✅ API Key Service initialized")
        print("  Note: Full CRUD tests require valid user_id in database")
        
        # Test validation without saving
        groq_key = os.getenv("GROQ_API_KEY")
        if groq_key:
            print("\n  Testing key validation...")
            result = await api_key_service.validate_key("groq", groq_key)
            print(f"  Validation result: {result['is_valid']}")
            if not result['is_valid']:
                print(f"  Error: {result.get('error')}")
        
    except Exception as e:
        print(f"⚠️  API Key Service test failed: {str(e)}")
        print("  This is expected if Supabase is not configured")


async def test_provider_chat():
    """Test provider chat functionality."""
    print("\n=== Testing Provider Chat ===")
    
    groq_key = os.getenv("GROQ_API_KEY")
    if not groq_key:
        print("⚠️  GROQ_API_KEY not set, skipping chat test")
        return
    
    try:
        provider = ProviderFactory.create_provider("groq", groq_key)
        
        messages = [
            {"role": "user", "content": "Say 'Hello' in one word."}
        ]
        
        print("  Sending test message to GROQ...")
        response = await provider.chat(messages, temperature=0.7, max_tokens=10)
        
        print(f"  Response: {response['content']}")
        print(f"  Tokens: {response['usage']['total_tokens']}")
        print(f"  Model: {response['model']}")
        print("✅ Chat test successful")
        
    except Exception as e:
        print(f"❌ Chat test failed: {str(e)}")


async def main():
    """Run all tests."""
    print("=" * 60)
    print("API Key Management System - Test Suite")
    print("=" * 60)
    
    await test_encryption()
    await test_provider_factory()
    await test_provider_chat()
    await test_api_key_service()
    
    print("\n" + "=" * 60)
    print("Test Suite Complete")
    print("=" * 60)
    print("\nNext Steps:")
    print("1. Apply database migration: migrations/006_user_api_keys.sql")
    print("2. Start backend: uv run python run.py")
    print("3. Test endpoints: curl http://localhost:8000/api/keys/providers")
    print("4. View API docs: http://localhost:8000/docs")


if __name__ == "__main__":
    asyncio.run(main())
