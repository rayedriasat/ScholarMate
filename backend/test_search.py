"""
Test script for Advanced Search functionality.
"""

import asyncio
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

from app.services.search_service import get_search_service


async def test_search():
    """Test search functionality."""
    
    print("=" * 60)
    print("Testing Advanced Search Service")
    print("=" * 60)
    
    # Initialize search service
    search_service = get_search_service()
    print("✓ Search service initialized")
    
    # Test user ID (replace with actual user ID from your database)
    test_user_id = os.getenv("TEST_USER_ID", "test-user-123")
    
    # Test queries
    test_queries = [
        "research",
        "machine learning",
        "neural networks",
        "pdf",
        "introduction",
    ]
    
    for query in test_queries:
        print(f"\n{'=' * 60}")
        print(f"Query: '{query}'")
        print(f"{'=' * 60}")
        
        try:
            # Perform search
            results = await search_service.search(
                query=query,
                user_id=test_user_id,
                max_results=10,
                include_semantic=True
            )
            
            print(f"Found {len(results)} results:")
            
            for i, result in enumerate(results, 1):
                print(f"\n{i}. {result.file_name}")
                print(f"   Match Type: {result.match_type}")
                print(f"   Relevance: {result.relevance_score:.2%}")
                print(f"   Context: {result.match_context or 'N/A'}")
                if result.page_number:
                    print(f"   Page: {result.page_number}")
                if result.snippet:
                    snippet = result.snippet[:100] + "..." if len(result.snippet) > 100 else result.snippet
                    print(f"   Snippet: {snippet}")
            
            if not results:
                print("   No results found")
                
        except Exception as e:
            print(f"✗ Search failed: {str(e)}")
    
    print(f"\n{'=' * 60}")
    print("Search tests completed")
    print(f"{'=' * 60}")


async def test_filename_search():
    """Test filename-only search."""
    
    print("\n" + "=" * 60)
    print("Testing Filename Search (No Semantic)")
    print("=" * 60)
    
    search_service = get_search_service()
    test_user_id = os.getenv("TEST_USER_ID", "test-user-123")
    
    query = "research"
    
    try:
        results = await search_service.search(
            query=query,
            user_id=test_user_id,
            max_results=10,
            include_semantic=False  # Filename only
        )
        
        print(f"\nQuery: '{query}' (filename only)")
        print(f"Found {len(results)} results:")
        
        for i, result in enumerate(results, 1):
            print(f"\n{i}. {result.file_name}")
            print(f"   Match Type: {result.match_type}")
            print(f"   Relevance: {result.relevance_score:.2%}")
            
    except Exception as e:
        print(f"✗ Search failed: {str(e)}")


if __name__ == "__main__":
    print("\n🔍 Advanced Search Test Suite\n")
    
    # Run tests
    asyncio.run(test_search())
    asyncio.run(test_filename_search())
    
    print("\n✓ All tests completed\n")
