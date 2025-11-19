"""
Test script for hybrid embedding system.
Tests API, local, and auto strategies.
"""

import asyncio
import os
import sys
from dotenv import load_dotenv

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.services.embedding_service import get_embedding_service, EmbeddingStrategy

# Load environment
load_dotenv()


async def test_api_strategy():
    """Test HuggingFace API embedding generation."""
    print("\n=== Testing API Strategy ===")
    
    try:
        service = get_embedding_service(strategy=EmbeddingStrategy.API)
        
        texts = [
            "This is a test document about machine learning.",
            "Another test about natural language processing."
        ]
        
        print(f"Generating embeddings for {len(texts)} texts via API...")
        embeddings = await service.generate_embeddings(texts, strategy=EmbeddingStrategy.API)
        
        print(f"✅ Success! Generated {len(embeddings)} embeddings")
        print(f"   Embedding dimension: {len(embeddings[0])}")
        print(f"   First 5 values: {embeddings[0][:5]}")
        
        return True
        
    except Exception as e:
        print(f"❌ API strategy failed: {str(e)}")
        return False


async def test_local_strategy():
    """Test local model embedding generation."""
    print("\n=== Testing Local Strategy ===")
    
    try:
        service = get_embedding_service(strategy=EmbeddingStrategy.LOCAL)
        
        texts = [
            "This is a test document about machine learning.",
            "Another test about natural language processing."
        ]
        
        print(f"Generating embeddings for {len(texts)} texts with local model...")
        embeddings = await service.generate_embeddings(texts, strategy=EmbeddingStrategy.LOCAL)
        
        print(f"✅ Success! Generated {len(embeddings)} embeddings")
        print(f"   Embedding dimension: {len(embeddings[0])}")
        print(f"   First 5 values: {embeddings[0][:5]}")
        
        return True
        
    except Exception as e:
        print(f"❌ Local strategy failed: {str(e)}")
        return False


async def test_auto_strategy():
    """Test automatic strategy selection."""
    print("\n=== Testing Auto Strategy ===")
    
    try:
        service = get_embedding_service(strategy=EmbeddingStrategy.AUTO)
        
        texts = [
            "This is a test document about machine learning.",
            "Another test about natural language processing."
        ]
        
        print(f"Generating embeddings for {len(texts)} texts with auto strategy...")
        embeddings = await service.generate_embeddings(texts, strategy=EmbeddingStrategy.AUTO)
        
        print(f"✅ Success! Generated {len(embeddings)} embeddings")
        print(f"   Embedding dimension: {len(embeddings[0])}")
        print(f"   First 5 values: {embeddings[0][:5]}")
        
        # Check which strategy was used
        api_available = await service.is_api_available()
        strategy_used = "API" if api_available else "Local"
        print(f"   Strategy used: {strategy_used}")
        
        return True
        
    except Exception as e:
        print(f"❌ Auto strategy failed: {str(e)}")
        return False


async def test_query_embedding():
    """Test single query embedding generation."""
    print("\n=== Testing Query Embedding ===")
    
    try:
        service = get_embedding_service(strategy=EmbeddingStrategy.AUTO)
        
        query = "What is machine learning?"
        
        print(f"Generating embedding for query: '{query}'")
        embedding = await service.generate_query_embedding(query)
        
        print(f"✅ Success! Generated query embedding")
        print(f"   Embedding dimension: {len(embedding)}")
        print(f"   First 5 values: {embedding[:5]}")
        
        return True
        
    except Exception as e:
        print(f"❌ Query embedding failed: {str(e)}")
        return False


async def test_api_health():
    """Test API availability check."""
    print("\n=== Testing API Health Check ===")
    
    try:
        service = get_embedding_service()
        
        print("Checking API availability...")
        api_available = await service.is_api_available()
        
        if api_available:
            print("✅ HuggingFace API is available")
        else:
            print("⚠️  HuggingFace API is not available (will use local fallback)")
        
        return True
        
    except Exception as e:
        print(f"❌ Health check failed: {str(e)}")
        return False


async def test_batch_processing():
    """Test batch processing with multiple texts."""
    print("\n=== Testing Batch Processing ===")
    
    try:
        service = get_embedding_service(strategy=EmbeddingStrategy.AUTO)
        
        # Generate 10 test texts
        texts = [f"This is test document number {i} about various topics." for i in range(10)]
        
        print(f"Generating embeddings for {len(texts)} texts in batch...")
        embeddings = await service.generate_embeddings(texts)
        
        print(f"✅ Success! Generated {len(embeddings)} embeddings")
        print(f"   Embedding dimension: {len(embeddings[0])}")
        print(f"   All embeddings have same dimension: {all(len(e) == len(embeddings[0]) for e in embeddings)}")
        
        return True
        
    except Exception as e:
        print(f"❌ Batch processing failed: {str(e)}")
        return False


async def main():
    """Run all tests."""
    print("=" * 60)
    print("Hybrid Embedding System Test Suite")
    print("=" * 60)
    
    # Check environment
    hf_token = os.getenv("HUGGINGFACEHUB_API_TOKEN")
    if hf_token:
        print(f"✅ HuggingFace token configured: {hf_token[:10]}...")
    else:
        print("⚠️  No HuggingFace token found (API tests may fail)")
    
    # Run tests
    results = []
    
    results.append(("API Health Check", await test_api_health()))
    results.append(("API Strategy", await test_api_strategy()))
    results.append(("Local Strategy", await test_local_strategy()))
    results.append(("Auto Strategy", await test_auto_strategy()))
    results.append(("Query Embedding", await test_query_embedding()))
    results.append(("Batch Processing", await test_batch_processing()))
    
    # Summary
    print("\n" + "=" * 60)
    print("Test Summary")
    print("=" * 60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status} - {test_name}")
    
    print(f"\nTotal: {passed}/{total} tests passed")
    
    if passed == total:
        print("\n🎉 All tests passed!")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed")
    
    return passed == total


if __name__ == "__main__":
    success = asyncio.run(main())
    sys.exit(0 if success else 1)
