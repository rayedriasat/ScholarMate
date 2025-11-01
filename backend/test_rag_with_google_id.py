"""
Test RAG query with Google user ID (not UUID).
This tests the user ID conversion fix.
"""
import asyncio
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

from app.services.rag_query_service import get_rag_query_service

async def test_rag_with_google_id():
    """Test RAG query using Google user ID"""
    google_user_id = "100368505623607269813"
    
    print(f"\n{'='*60}")
    print(f"Testing RAG with Google User ID: {google_user_id}")
    print(f"{'='*60}\n")
    
    try:
        rag_service = get_rag_query_service()
        
        # This should convert Google ID to UUID automatically
        print(f"🔄 Converting Google ID to Supabase UUID...")
        uuid = await rag_service._get_or_create_user_uuid(google_user_id)
        print(f"✅ Resolved to UUID: {uuid}\n")
        
        # Check if this UUID has documents
        from app.services.chroma_service import get_chroma_service
        chroma_service = get_chroma_service()
        stats = chroma_service.get_collection_stats(uuid)
        
        print(f"📊 Collection Stats:")
        print(f"   UUID: {uuid}")
        print(f"   Documents: {stats['document_count']}\n")
        
        if stats['document_count'] == 0:
            print(f"❌ No documents indexed for this UUID")
            print(f"\n💡 This means the indexing used a different UUID.")
            print(f"   Check which UUID was used during indexing.\n")
            return
        
        # Test a query
        print(f"🔍 Testing query: 'What is this document about?'\n")
        
        response = await rag_service.query(
            question="What is this document about?",
            user_id=google_user_id,  # Pass Google ID, should auto-convert
            top_k=3
        )
        
        print(f"✅ Query successful!")
        print(f"\n📝 Response:")
        print(f"   {response.message[:200]}...")
        print(f"\n📚 Citations: {len(response.citations)}")
        
        for i, citation in enumerate(response.citations[:3], 1):
            print(f"   {i}. {citation.file_name} (Page {citation.page_number})")
        
        print(f"\n✅ RAG with Google ID conversion is working!\n")
        
    except Exception as e:
        print(f"\n❌ Test failed: {e}\n")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    asyncio.run(test_rag_with_google_id())
