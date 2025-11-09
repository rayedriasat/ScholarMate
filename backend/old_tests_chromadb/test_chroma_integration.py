"""
Integration test for ChromaDB with LangChain and GROQ embeddings.
Tests the complete RAG indexing pipeline.
"""

import asyncio
import sys
import os
from uuid import uuid4

# Add app directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from app.services.chroma_service import get_chroma_service
from app.services.groq_service import get_groq_service


async def test_chroma_with_groq():
    """Test ChromaDB integration with GROQ embeddings."""
    print("=" * 60)
    print("Testing ChromaDB + GROQ Integration")
    print("=" * 60)
    
    chroma_service = get_chroma_service()
    groq_service = get_groq_service()
    
    # Create test user
    test_user_id = str(uuid4())
    print(f"\nTest User ID: {test_user_id}")
    
    # Test 1: Create collection
    print("\n[Test 1] Creating user collection...")
    collection = chroma_service.get_or_create_user_collection(test_user_id)
    print(f"✓ Created collection: {collection.name}")
    
    # Test 2: Add documents with metadata
    print("\n[Test 2] Adding documents with metadata...")
    documents = [
        "Machine learning is a subset of artificial intelligence that focuses on learning from data.",
        "Python is a popular programming language for data science and machine learning.",
        "Neural networks are inspired by the structure of the human brain.",
        "Deep learning uses multiple layers of neural networks to learn complex patterns.",
        "Natural language processing enables computers to understand human language."
    ]
    
    metadatas = [
        {"file_id": "ml_basics.pdf", "page_number": 1, "chunk_index": 0},
        {"file_id": "ml_basics.pdf", "page_number": 2, "chunk_index": 1},
        {"file_id": "neural_nets.pdf", "page_number": 1, "chunk_index": 0},
        {"file_id": "neural_nets.pdf", "page_number": 2, "chunk_index": 1},
        {"file_id": "nlp_intro.pdf", "page_number": 1, "chunk_index": 0}
    ]
    
    ids = [f"doc_{i}" for i in range(len(documents))]
    
    chroma_service.add_documents(
        user_id=test_user_id,
        documents=documents,
        metadatas=metadatas,
        ids=ids
    )
    print(f"✓ Added {len(documents)} documents")
    
    # Test 3: Query without file filter
    print("\n[Test 3] Querying all documents...")
    results = chroma_service.query_documents(
        user_id=test_user_id,
        query_texts=["What is machine learning?"],
        n_results=3
    )
    
    print(f"✓ Found {len(results['ids'][0])} results")
    for i, (doc, metadata, distance) in enumerate(zip(
        results['documents'][0],
        results['metadatas'][0],
        results['distances'][0]
    )):
        print(f"\n  Result {i+1}:")
        print(f"    File: {metadata['file_id']}, Page: {metadata['page_number']}")
        print(f"    Distance: {distance:.4f}")
        print(f"    Text: {doc[:80]}...")
    
    # Test 4: Query with file filter (source selection)
    print("\n[Test 4] Querying with file filter (source selection)...")
    results_filtered = chroma_service.query_documents(
        user_id=test_user_id,
        query_texts=["neural networks"],
        n_results=3,
        where={"file_id": "neural_nets.pdf"}
    )
    
    print(f"✓ Found {len(results_filtered['ids'][0])} results from neural_nets.pdf")
    for i, (doc, metadata) in enumerate(zip(
        results_filtered['documents'][0],
        results_filtered['metadatas'][0]
    )):
        print(f"\n  Result {i+1}:")
        print(f"    File: {metadata['file_id']}, Page: {metadata['page_number']}")
        print(f"    Text: {doc[:80]}...")
    
    # Verify all results are from the filtered file
    all_from_filtered_file = all(
        m['file_id'] == 'neural_nets.pdf' 
        for m in results_filtered['metadatas'][0]
    )
    assert all_from_filtered_file, "All results should be from neural_nets.pdf"
    print("✓ Source filtering works correctly")
    
    # Test 5: Get collection stats
    print("\n[Test 5] Getting collection statistics...")
    stats = chroma_service.get_collection_stats(test_user_id)
    print(f"✓ Collection stats:")
    print(f"    Name: {stats['collection_name']}")
    print(f"    Documents: {stats['document_count']}")
    
    # Test 6: Delete documents by file
    print("\n[Test 6] Deleting documents by file...")
    chroma_service.delete_documents_by_file(test_user_id, "ml_basics.pdf")
    
    stats_after = chroma_service.get_collection_stats(test_user_id)
    print(f"✓ Documents after deletion: {stats_after['document_count']}")
    assert stats_after['document_count'] == 3, "Should have 3 documents left"
    
    # Test 7: Clean up
    print("\n[Test 7] Cleaning up test collection...")
    chroma_service.delete_user_collection(test_user_id)
    print("✓ Test collection deleted")
    
    print("\n" + "=" * 60)
    print("✅ All integration tests passed!")
    print("=" * 60)


async def test_groq_connection():
    """Test GROQ service connectivity."""
    print("\n" + "=" * 60)
    print("Testing GROQ Service Connection")
    print("=" * 60)
    
    groq_service = get_groq_service()
    
    print("\n[Test 1] Testing GROQ API connection...")
    result = groq_service.test_connection()
    
    if result['status'] == 'success':
        print(f"✓ GROQ connection successful")
        print(f"  Model: {result['model']}")
        print(f"  Response: {result['response']}")
    else:
        print(f"❌ GROQ connection failed: {result['error']}")
        return False
    
    print("\n[Test 2] Testing GROQ chat completion...")
    try:
        response = await groq_service.chat(
            messages=[
                {"role": "user", "content": "What is 2+2? Answer with just the number."}
            ],
            max_tokens=10
        )
        print(f"✓ Chat completion successful")
        print(f"  Response: {response['content']}")
        print(f"  Tokens used: {response['usage']['total_tokens']}")
    except Exception as e:
        print(f"❌ Chat completion failed: {str(e)}")
        return False
    
    print("\n" + "=" * 60)
    print("✅ GROQ service tests passed!")
    print("=" * 60)
    return True


if __name__ == "__main__":
    try:
        # Load environment variables
        from dotenv import load_dotenv
        load_dotenv()
        
        print("\n🚀 Starting ChromaDB + GROQ Integration Tests\n")
        
        # Test GROQ connection first
        groq_success = asyncio.run(test_groq_connection())
        
        if groq_success:
            # Test ChromaDB integration
            asyncio.run(test_chroma_with_groq())
        else:
            print("\n⚠️  Skipping ChromaDB tests due to GROQ connection failure")
        
        print("\n✅ All tests completed!\n")
        
    except Exception as e:
        print(f"\n❌ Test failed with error: {str(e)}\n")
        import traceback
        traceback.print_exc()
        sys.exit(1)
