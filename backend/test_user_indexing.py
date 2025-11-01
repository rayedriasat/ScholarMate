"""
Quick test to verify user has indexed documents and can query them.
Usage: uv run python test_user_indexing.py <user_id>
"""
import sys
import asyncio
from app.services.chroma_service import get_chroma_service
from app.services.rag_query_service import get_rag_query_service

async def test_user_indexing(user_id: str):
    """Test if user can query their indexed documents"""
    print(f"\n{'='*60}")
    print(f"Testing RAG for user: {user_id}")
    print(f"{'='*60}\n")
    
    # Step 1: Check collection stats
    chroma_service = get_chroma_service()
    stats = chroma_service.get_collection_stats(user_id)
    
    print(f"📊 Collection Stats:")
    print(f"   Collection: {stats['collection_name']}")
    print(f"   Documents: {stats['document_count']}")
    
    if stats['document_count'] == 0:
        print(f"\n❌ ERROR: No documents indexed!")
        print(f"\n💡 Solution:")
        print(f"   1. Open the app and go to File Explorer")
        print(f"   2. Right-click on a PDF file")
        print(f"   3. Select 'Reindex for AI'")
        print(f"   4. Wait for indexing to complete")
        print(f"   5. Try chatting again\n")
        return
    
    print(f"\n✅ Documents are indexed!\n")
    
    # Step 2: Test a simple query
    print(f"🔍 Testing query: 'What is this document about?'\n")
    
    try:
        rag_service = get_rag_query_service()
        response = await rag_service.query(
            question="What is this document about?",
            user_id=user_id,
            top_k=3
        )
        
        print(f"✅ Query successful!")
        print(f"\n📝 Response:")
        print(f"   {response.message[:200]}...")
        print(f"\n📚 Citations: {len(response.citations)}")
        
        for i, citation in enumerate(response.citations[:3], 1):
            print(f"   {i}. {citation.file_name} (Page {citation.page_number})")
        
        print(f"\n✅ RAG is working correctly!\n")
        
    except Exception as e:
        print(f"\n❌ Query failed: {e}\n")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        user_id = sys.argv[1]
    else:
        # Default Google user ID
        user_id = "111319857386978820359"
    
    asyncio.run(test_user_indexing(user_id))
