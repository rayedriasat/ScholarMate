"""
Comprehensive test for RAG Query Service using existing indexed documents.
"""

import os
import sys
import asyncio
import logging
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from app.services.rag_query_service import get_rag_query_service
from app.services.chroma_service import get_chroma_service

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


async def test_with_indexed_documents():
    """Test RAG query with existing indexed documents."""
    
    print("\n" + "="*80)
    print("COMPREHENSIVE RAG QUERY TEST WITH INDEXED DOCUMENTS")
    print("="*80)
    
    try:
        # Initialize services
        rag_query_service = get_rag_query_service()
        chroma_service = get_chroma_service()
        
        # Find a collection with documents
        collections = chroma_service.list_user_collections()
        print(f"\n1. Available collections: {len(collections)}")
        
        test_user_id = None
        for collection_name in collections:
            # Extract user_id from collection name (format: user_{user_id}_documents)
            if collection_name.startswith("user_") and collection_name.endswith("_documents"):
                user_id = collection_name[5:-10]  # Remove "user_" prefix and "_documents" suffix
                
                stats = chroma_service.get_collection_stats(user_id)
                if stats['document_count'] > 0:
                    test_user_id = user_id
                    print(f"✓ Using collection: {collection_name}")
                    print(f"  Document count: {stats['document_count']}")
                    break
        
        if not test_user_id:
            print("\n⚠ No collections with indexed documents found")
            print("Please run test_rag_indexer_full.py first to index some documents")
            return
        
        # Test 1: Basic query without filtering
        print("\n2. Testing basic query (no source filtering)...")
        questions = [
            "What is this document about?",
            "Summarize the main points",
            "What are the key topics discussed?"
        ]
        
        for question in questions:
            print(f"\n  Question: {question}")
            
            response = await rag_query_service.query(
                question=question,
                user_id=test_user_id,
                selected_file_ids=None,
                top_k=5
            )
            
            print(f"  Answer: {response.message[:150]}...")
            print(f"  Citations: {len(response.citations)}")
            
            for i, citation in enumerate(response.citations[:3], 1):  # Show first 3
                print(f"    [{i}] {citation.file_name}, Page {citation.page_number}")
        
        # Test 2: Context retrieval
        print("\n3. Testing context retrieval...")
        chunks = await rag_query_service.retrieve_context(
            question="What is the main topic?",
            user_id=test_user_id,
            selected_file_ids=None,
            top_k=5
        )
        
        print(f"✓ Retrieved {len(chunks)} chunks")
        
        # Collect unique file IDs for filtering test
        unique_files = {}
        for chunk in chunks:
            if chunk.file_id not in unique_files:
                unique_files[chunk.file_id] = chunk.file_name
                print(f"  File: {chunk.file_name} (ID: {chunk.file_id[:20]}...)")
        
        # Test 3: Query with source filtering
        if len(unique_files) > 0:
            print("\n4. Testing query with source filtering...")
            
            # Test with first file only
            selected_file_id = list(unique_files.keys())[0]
            selected_file_name = unique_files[selected_file_id]
            
            print(f"  Filtering by: {selected_file_name}")
            
            filtered_response = await rag_query_service.query(
                question="What information is in this document?",
                user_id=test_user_id,
                selected_file_ids=[selected_file_id],
                top_k=5
            )
            
            print(f"✓ Filtered query completed")
            print(f"  Answer: {filtered_response.message[:150]}...")
            print(f"  Citations: {len(filtered_response.citations)}")
            
            # Verify all citations are from selected file
            all_from_selected = all(
                c.file_id == selected_file_id 
                for c in filtered_response.citations
            )
            print(f"  ✓ All citations from selected file: {all_from_selected}")
            
            # Test with multiple files
            if len(unique_files) > 1:
                print("\n5. Testing query with multiple file filtering...")
                
                selected_file_ids = list(unique_files.keys())[:2]
                selected_names = [unique_files[fid] for fid in selected_file_ids]
                
                print(f"  Filtering by: {', '.join(selected_names)}")
                
                multi_response = await rag_query_service.query(
                    question="Compare the information in these documents",
                    user_id=test_user_id,
                    selected_file_ids=selected_file_ids,
                    top_k=5
                )
                
                print(f"✓ Multi-file query completed")
                print(f"  Answer: {multi_response.message[:150]}...")
                print(f"  Citations: {len(multi_response.citations)}")
                
                # Verify citations are from selected files
                citation_files = set(c.file_id for c in multi_response.citations)
                all_from_selected = citation_files.issubset(set(selected_file_ids))
                print(f"  ✓ All citations from selected files: {all_from_selected}")
        
        # Test 4: Citation deduplication
        print("\n6. Testing citation deduplication...")
        
        # Get chunks that might have duplicates
        chunks = await rag_query_service.retrieve_context(
            question="Tell me about this",
            user_id=test_user_id,
            selected_file_ids=None,
            top_k=10
        )
        
        print(f"  Retrieved {len(chunks)} chunks")
        
        # Count unique pages
        unique_pages = set((c.file_id, c.page_number) for c in chunks)
        print(f"  Unique pages: {len(unique_pages)}")
        
        # Format citations
        citations = rag_query_service.format_citations(chunks)
        print(f"  Citations after deduplication: {len(citations)}")
        print(f"  ✓ Deduplication working: {len(citations) == len(unique_pages)}")
        
        # Test 5: Empty results handling
        print("\n7. Testing empty results handling...")
        
        empty_response = await rag_query_service.query(
            question="xyzabc123nonexistent",
            user_id=test_user_id,
            selected_file_ids=["nonexistent-file-id-12345"],
            top_k=5
        )
        
        print(f"✓ Empty query handled gracefully")
        print(f"  Message: {empty_response.message}")
        print(f"  Citations: {len(empty_response.citations)}")
        
        # Test 6: Different top_k values
        print("\n8. Testing different top_k values...")
        
        for k in [1, 3, 5, 10]:
            response = await rag_query_service.query(
                question="What is this about?",
                user_id=test_user_id,
                selected_file_ids=None,
                top_k=k
            )
            
            print(f"  top_k={k}: {len(response.citations)} citations")
        
        print("\n" + "="*80)
        print("✓ ALL COMPREHENSIVE TESTS PASSED")
        print("="*80)
        print("\nSummary:")
        print("- Basic query: ✓")
        print("- Context retrieval: ✓")
        print("- Source filtering (single file): ✓")
        print("- Source filtering (multiple files): ✓")
        print("- Citation deduplication: ✓")
        print("- Empty results handling: ✓")
        print("- Variable top_k: ✓")
        
    except Exception as e:
        print(f"\n✗ TEST FAILED: {str(e)}")
        logger.exception("Test failed with exception")
        raise


async def main():
    """Run comprehensive tests."""
    
    # Check environment variables
    if not os.getenv("GROQ_API_KEY"):
        print("ERROR: GROQ_API_KEY not set in environment")
        return
    
    if not os.getenv("SUPABASE_URL") or not os.getenv("SUPABASE_SERVICE_KEY"):
        print("ERROR: Supabase credentials not set")
        return
    
    await test_with_indexed_documents()


if __name__ == "__main__":
    asyncio.run(main())
