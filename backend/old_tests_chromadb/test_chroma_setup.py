"""
Test script for ChromaDB setup and user isolation.
Verifies that per-user collections work correctly.
"""

import asyncio
import sys
import os
from uuid import uuid4

# Add app directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'app'))

from app.services.chroma_service import get_chroma_service


def test_user_isolation():
    """Test that users have separate collections and cannot access each other's data."""
    print("=" * 60)
    print("Testing ChromaDB User Isolation")
    print("=" * 60)
    
    chroma_service = get_chroma_service()
    
    # Create test user IDs
    user1_id = str(uuid4())
    user2_id = str(uuid4())
    
    print(f"\nTest User 1 ID: {user1_id}")
    print(f"Test User 2 ID: {user2_id}")
    
    # Test 1: Create collections for both users
    print("\n[Test 1] Creating collections for both users...")
    collection1 = chroma_service.get_or_create_user_collection(user1_id)
    collection2 = chroma_service.get_or_create_user_collection(user2_id)
    
    print(f"✓ User 1 collection: {collection1.name}")
    print(f"✓ User 2 collection: {collection2.name}")
    
    assert collection1.name != collection2.name, "Collections should have different names"
    print("✓ Collections have different names")
    
    # Test 2: Add documents to user 1's collection
    print("\n[Test 2] Adding documents to User 1's collection...")
    user1_docs = [
        "This is a document about machine learning.",
        "Python is a great programming language.",
        "ChromaDB is a vector database."
    ]
    user1_metadatas = [
        {"file_id": "file1", "page_number": 1, "chunk_index": 0},
        {"file_id": "file1", "page_number": 2, "chunk_index": 1},
        {"file_id": "file2", "page_number": 1, "chunk_index": 0}
    ]
    user1_ids = [f"user1_doc_{i}" for i in range(len(user1_docs))]
    
    chroma_service.add_documents(
        user_id=user1_id,
        documents=user1_docs,
        metadatas=user1_metadatas,
        ids=user1_ids
    )
    print(f"✓ Added {len(user1_docs)} documents to User 1's collection")
    
    # Test 3: Add documents to user 2's collection
    print("\n[Test 3] Adding documents to User 2's collection...")
    user2_docs = [
        "This is a document about quantum computing.",
        "JavaScript is used for web development."
    ]
    user2_metadatas = [
        {"file_id": "file3", "page_number": 1, "chunk_index": 0},
        {"file_id": "file3", "page_number": 2, "chunk_index": 1}
    ]
    user2_ids = [f"user2_doc_{i}" for i in range(len(user2_docs))]
    
    chroma_service.add_documents(
        user_id=user2_id,
        documents=user2_docs,
        metadatas=user2_metadatas,
        ids=user2_ids
    )
    print(f"✓ Added {len(user2_docs)} documents to User 2's collection")
    
    # Test 4: Verify collection stats
    print("\n[Test 4] Verifying collection statistics...")
    stats1 = chroma_service.get_collection_stats(user1_id)
    stats2 = chroma_service.get_collection_stats(user2_id)
    
    print(f"User 1 collection: {stats1['document_count']} documents")
    print(f"User 2 collection: {stats2['document_count']} documents")
    
    assert stats1['document_count'] == 3, "User 1 should have 3 documents"
    assert stats2['document_count'] == 2, "User 2 should have 2 documents"
    print("✓ Document counts are correct")
    
    # Test 5: Query user 1's collection
    print("\n[Test 5] Querying User 1's collection...")
    results1 = chroma_service.query_documents(
        user_id=user1_id,
        query_texts=["programming language"],
        n_results=2
    )
    
    print(f"Query results for User 1: {len(results1['ids'][0])} documents")
    print(f"Top result: {results1['documents'][0][0][:50]}...")
    
    assert len(results1['ids'][0]) > 0, "Should return results for User 1"
    print("✓ User 1 can query their own documents")
    
    # Test 6: Query user 2's collection
    print("\n[Test 6] Querying User 2's collection...")
    results2 = chroma_service.query_documents(
        user_id=user2_id,
        query_texts=["quantum computing"],
        n_results=2
    )
    
    print(f"Query results for User 2: {len(results2['ids'][0])} documents")
    print(f"Top result: {results2['documents'][0][0][:50]}...")
    
    assert len(results2['ids'][0]) > 0, "Should return results for User 2"
    print("✓ User 2 can query their own documents")
    
    # Test 7: Verify isolation - User 1 shouldn't see User 2's documents
    print("\n[Test 7] Verifying data isolation...")
    user1_results = chroma_service.query_documents(
        user_id=user1_id,
        query_texts=["quantum computing"],
        n_results=5
    )
    
    # Check that none of user 2's documents appear in user 1's results
    user1_result_texts = user1_results['documents'][0]
    user2_doc_found = any("quantum computing" in doc for doc in user1_result_texts)
    
    assert not user2_doc_found, "User 1 should not see User 2's documents"
    print("✓ User 1 cannot access User 2's documents")
    
    # Test 8: Test file-based deletion
    print("\n[Test 8] Testing file-based document deletion...")
    chroma_service.delete_documents_by_file(user1_id, "file1")
    
    stats1_after = chroma_service.get_collection_stats(user1_id)
    print(f"User 1 documents after deletion: {stats1_after['document_count']}")
    
    assert stats1_after['document_count'] == 1, "Should have 1 document left (from file2)"
    print("✓ File-based deletion works correctly")
    
    # Test 9: List all collections
    print("\n[Test 9] Listing all collections...")
    all_collections = chroma_service.list_user_collections()
    print(f"Total collections: {len(all_collections)}")
    for col_name in all_collections:
        print(f"  - {col_name}")
    
    assert len(all_collections) >= 2, "Should have at least 2 collections"
    print("✓ Collection listing works")
    
    # Test 10: Clean up test collections
    print("\n[Test 10] Cleaning up test collections...")
    deleted1 = chroma_service.delete_user_collection(user1_id)
    deleted2 = chroma_service.delete_user_collection(user2_id)
    
    assert deleted1 and deleted2, "Both collections should be deleted"
    print("✓ Test collections cleaned up successfully")
    
    print("\n" + "=" * 60)
    print("✅ All tests passed! User isolation is working correctly.")
    print("=" * 60)


def test_collection_naming():
    """Test that collection names are properly formatted."""
    print("\n" + "=" * 60)
    print("Testing Collection Naming")
    print("=" * 60)
    
    chroma_service = get_chroma_service()
    
    # Test with UUID format (with hyphens)
    test_uuid = "550e8400-e29b-41d4-a716-446655440000"
    collection_name = chroma_service.get_user_collection_name(test_uuid)
    
    print(f"\nInput UUID: {test_uuid}")
    print(f"Collection name: {collection_name}")
    
    # Verify format
    assert collection_name.startswith("user_"), "Should start with 'user_'"
    assert collection_name.endswith("_documents"), "Should end with '_documents'"
    assert "-" not in collection_name, "Should not contain hyphens"
    assert "_" in collection_name, "Should contain underscores"
    
    print("✓ Collection naming format is correct")
    print("=" * 60)


if __name__ == "__main__":
    try:
        # Load environment variables
        from dotenv import load_dotenv
        load_dotenv()
        
        print("\n🚀 Starting ChromaDB Setup Tests\n")
        
        # Run tests
        test_collection_naming()
        test_user_isolation()
        
        print("\n✅ All ChromaDB tests completed successfully!\n")
        
    except Exception as e:
        print(f"\n❌ Test failed with error: {str(e)}\n")
        import traceback
        traceback.print_exc()
        sys.exit(1)
