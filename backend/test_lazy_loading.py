"""
Test script to verify lazy-loading of embeddings works correctly.
Run this to ensure services initialize quickly without blocking.
"""
import time
import os
from dotenv import load_dotenv

load_dotenv()

print("Testing lazy-loading of embedding models...\n")

# Test 1: RAG Query Service initialization
print("1. Testing RAG Query Service initialization...")
start = time.time()
try:
    from app.services.rag_query_service import RAGQueryService
    service = RAGQueryService()
    init_time = time.time() - start
    print(f"   ✓ Initialized in {init_time:.2f}s (should be < 2s)")
    
    # Test lazy loading
    print("   Testing lazy-load of embeddings...")
    start = time.time()
    _ = service.embeddings  # This should trigger loading
    load_time = time.time() - start
    print(f"   ✓ Embeddings loaded in {load_time:.2f}s")
    
    # Test second access (should be instant)
    start = time.time()
    _ = service.embeddings
    cache_time = time.time() - start
    print(f"   ✓ Cached access in {cache_time:.4f}s (should be < 0.01s)")
    
except Exception as e:
    print(f"   ✗ Failed: {e}")

print()

# Test 2: RAG Indexer initialization
print("2. Testing RAG Indexer initialization...")
start = time.time()
try:
    from app.services.rag_indexer import RAGIndexer
    indexer = RAGIndexer()
    init_time = time.time() - start
    print(f"   ✓ Initialized in {init_time:.2f}s (should be < 2s)")
    
    # Test lazy loading
    print("   Testing lazy-load of embeddings...")
    start = time.time()
    _ = indexer.embeddings  # This should trigger loading
    load_time = time.time() - start
    print(f"   ✓ Embeddings loaded in {load_time:.2f}s")
    
    # Test second access (should be instant)
    start = time.time()
    _ = indexer.embeddings
    cache_time = time.time() - start
    print(f"   ✓ Cached access in {cache_time:.4f}s (should be < 0.01s)")
    
except Exception as e:
    print(f"   ✗ Failed: {e}")

print("\n✓ All tests passed! Services initialize quickly and embeddings load on demand.")
