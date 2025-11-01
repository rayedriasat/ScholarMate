"""
Test RAG Query Service with LangChain and GROQ.
Tests semantic search, source filtering, and citation generation.
"""

import os
import sys
import asyncio
import logging
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from app.services.rag_query_service import get_rag_query_service, Citation, RetrievedChunk
from app.services.chroma_service import get_chroma_service
from app.services.groq_service import get_groq_service

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


async def test_rag_query_service():
    """Test RAG query service functionality."""
    
    print("\n" + "="*80)
    print("RAG QUERY SERVICE TEST")
    print("="*80)
    
    try:
        # Initialize service
        print("\n1. Initializing RAG Query Service...")
        rag_query_service = get_rag_query_service()
        print("✓ RAG Query Service initialized")
        
        # Test user ID (use a test user that has indexed documents)
        test_user_id = os.getenv("TEST_USER_ID", "test-user-123")
        print(f"✓ Using test user: {test_user_id}")
        
        # Check if user has any documents indexed
        print("\n2. Checking user's vector store...")
        chroma_service = get_chroma_service()
        stats = chroma_service.get_collection_stats(test_user_id)
        print(f"✓ Collection stats: {stats}")
        
        if stats['document_count'] == 0:
            print("\n⚠ No documents indexed for test user")
            print("Please run test_rag_indexer.py first to index some documents")
            return
        
        # Test 1: Basic query without source filtering
        print("\n3. Testing basic query (no source filtering)...")
        question = "What is this document about?"
        
        response = await rag_query_service.query(
            question=question,
            user_id=test_user_id,
            selected_file_ids=None,
            top_k=5
        )
        
        print(f"✓ Query completed")
        print(f"  Question: {question}")
        print(f"  Answer: {response.message[:200]}...")
        print(f"  Citations: {len(response.citations)}")
        
        for i, citation in enumerate(response.citations, 1):
            print(f"    [{i}] {citation.file_name}, Page {citation.page_number}")
        
        # Test 2: Retrieve context
        print("\n4. Testing context retrieval...")
        chunks = await rag_query_service.retrieve_context(
            question=question,
            user_id=test_user_id,
            selected_file_ids=None,
            top_k=3
        )
        
        print(f"✓ Retrieved {len(chunks)} chunks")
        for i, chunk in enumerate(chunks, 1):
            print(f"  Chunk {i}:")
            print(f"    File: {chunk.file_name}")
            print(f"    Page: {chunk.page_number}")
            print(f"    Content: {chunk.content[:100]}...")
            print(f"    Distance: {chunk.distance:.4f}")
        
        # Test 3: Query with source filtering
        if response.citations:
            print("\n5. Testing query with source filtering...")
            # Use first citation's file_id for filtering
            selected_file_id = response.citations[0].file_id
            
            filtered_response = await rag_query_service.query(
                question=question,
                user_id=test_user_id,
                selected_file_ids=[selected_file_id],
                top_k=3
            )
            
            print(f"✓ Filtered query completed")
            print(f"  Selected file: {response.citations[0].file_name}")
            print(f"  Answer: {filtered_response.message[:200]}...")
            print(f"  Citations: {len(filtered_response.citations)}")
            
            # Verify all citations are from selected file
            all_from_selected = all(
                c.file_id == selected_file_id 
                for c in filtered_response.citations
            )
            print(f"  All citations from selected file: {all_from_selected}")
        
        # Test 4: Citation formatting
        print("\n6. Testing citation formatting...")
        test_chunks = [
            RetrievedChunk(
                content="This is test content from page 1",
                file_id="file1",
                file_name="Test Document.pdf",
                page_number=1,
                chunk_index=0,
                distance=0.1
            ),
            RetrievedChunk(
                content="This is more content from page 1",
                file_id="file1",
                file_name="Test Document.pdf",
                page_number=1,  # Same page, should deduplicate
                chunk_index=1,
                distance=0.2
            ),
            RetrievedChunk(
                content="This is content from page 2",
                file_id="file1",
                file_name="Test Document.pdf",
                page_number=2,
                chunk_index=2,
                distance=0.3
            ),
        ]
        
        citations = rag_query_service.format_citations(test_chunks)
        print(f"✓ Formatted {len(citations)} citations from {len(test_chunks)} chunks")
        print(f"  Expected 2 citations (deduplication by page)")
        print(f"  Actual: {len(citations)} citations")
        
        for citation in citations:
            print(f"    - {citation.file_name}, Page {citation.page_number}")
        
        # Test 5: Get user vectorstore
        print("\n7. Testing get_user_vectorstore...")
        vectorstore = await rag_query_service.get_user_vectorstore(test_user_id)
        print(f"✓ Retrieved vectorstore: {vectorstore.name}")
        
        # Test 6: Empty query handling
        print("\n8. Testing empty results handling...")
        empty_response = await rag_query_service.query(
            question="xyzabc123nonexistent",
            user_id=test_user_id,
            selected_file_ids=["nonexistent-file-id"],
            top_k=5
        )
        
        print(f"✓ Empty query handled gracefully")
        print(f"  Message: {empty_response.message}")
        print(f"  Citations: {len(empty_response.citations)}")
        
        print("\n" + "="*80)
        print("✓ ALL TESTS PASSED")
        print("="*80)
        
    except Exception as e:
        print(f"\n✗ TEST FAILED: {str(e)}")
        logger.exception("Test failed with exception")
        raise


async def test_groq_integration():
    """Test GROQ service integration."""
    
    print("\n" + "="*80)
    print("GROQ INTEGRATION TEST")
    print("="*80)
    
    try:
        print("\n1. Testing GROQ service...")
        groq_service = get_groq_service()
        
        # Test chat
        print("\n2. Testing GROQ chat...")
        messages = [
            {"role": "user", "content": "Say 'Hello from GROQ' if you can hear me."}
        ]
        
        response = await groq_service.chat(messages=messages, max_tokens=50)
        print(f"✓ GROQ chat response: {response['content']}")
        print(f"  Tokens used: {response['usage']['total_tokens']}")
        
        print("\n" + "="*80)
        print("✓ GROQ INTEGRATION TEST PASSED")
        print("="*80)
        
    except Exception as e:
        print(f"\n✗ GROQ TEST FAILED: {str(e)}")
        logger.exception("GROQ test failed")
        raise


async def main():
    """Run all tests."""
    
    # Check environment variables
    if not os.getenv("GROQ_API_KEY"):
        print("ERROR: GROQ_API_KEY not set in environment")
        print("Please set GROQ_API_KEY in backend/.env")
        return
    
    if not os.getenv("SUPABASE_URL") or not os.getenv("SUPABASE_SERVICE_KEY"):
        print("ERROR: Supabase credentials not set")
        print("Please set SUPABASE_URL and SUPABASE_SERVICE_KEY in backend/.env")
        return
    
    # Run tests
    await test_groq_integration()
    await test_rag_query_service()


if __name__ == "__main__":
    asyncio.run(main())
