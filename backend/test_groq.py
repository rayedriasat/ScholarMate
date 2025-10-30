"""
Test script for GROQ AI integration.
Run with: uv run python test_groq.py
"""

import asyncio
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

from app.services.groq_service import get_groq_service


async def test_groq_chat():
    """Test GROQ chat completion."""
    print("\n=== Testing GROQ Chat Completion ===")
    
    try:
        groq_service = get_groq_service()
        
        # Test simple chat
        messages = [
            {"role": "user", "content": "What is the capital of France? Answer in one word."}
        ]
        
        result = await groq_service.chat(messages=messages, max_tokens=10)
        
        print(f"✓ Chat Response: {result['content']}")
        print(f"✓ Model: {result['model']}")
        print(f"✓ Tokens Used: {result['usage']['total_tokens']}")
        
        return True
        
    except Exception as e:
        print(f"✗ Chat test failed: {str(e)}")
        return False


async def test_groq_embeddings():
    """Test GROQ embeddings (placeholder)."""
    print("\n=== Testing GROQ Embeddings ===")
    
    try:
        groq_service = get_groq_service()
        
        texts = ["Hello world", "Test embedding"]
        embeddings = await groq_service.embed(texts)
        
        print(f"✓ Generated {len(embeddings)} embeddings")
        print(f"✓ Embedding dimension: {len(embeddings[0])}")
        
        return True
        
    except Exception as e:
        print(f"✗ Embedding test failed: {str(e)}")
        return False


def test_groq_connection():
    """Test GROQ API connection."""
    print("\n=== Testing GROQ Connection ===")
    
    try:
        groq_service = get_groq_service()
        result = groq_service.test_connection()
        
        if result["status"] == "success":
            print(f"✓ Connection successful")
            print(f"✓ Model: {result['model']}")
            print(f"✓ Response: {result['response']}")
            return True
        else:
            print(f"✗ Connection failed: {result.get('error', 'Unknown error')}")
            return False
            
    except Exception as e:
        print(f"✗ Connection test failed: {str(e)}")
        return False


async def main():
    """Run all tests."""
    print("=" * 50)
    print("GROQ AI Integration Tests")
    print("=" * 50)
    
    # Check API key
    api_key = os.getenv("GROQ_API_KEY")
    if not api_key or api_key == "your_groq_api_key":
        print("\n✗ GROQ_API_KEY not configured in .env file")
        print("Please add a valid GROQ API key to backend/.env")
        return
    
    print(f"\n✓ GROQ_API_KEY found: {api_key[:10]}...")
    
    # Run tests
    results = []
    
    results.append(test_groq_connection())
    results.append(await test_groq_chat())
    results.append(await test_groq_embeddings())
    
    # Summary
    print("\n" + "=" * 50)
    print(f"Tests Passed: {sum(results)}/{len(results)}")
    print("=" * 50)


if __name__ == "__main__":
    asyncio.run(main())
