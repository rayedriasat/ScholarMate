"""
Debug script to test notebook AI generation with actual file IDs.
Run this to see exactly what's happening with file ID resolution.
"""

import asyncio
import sys
from app.services.rag_query_service import get_rag_query_service

async def test_file_retrieval():
    """Test if we can retrieve content from files."""
    
    # Replace these with actual values from your system
    USER_ID = "YOUR_USER_ID_HERE"  # Get from Supabase users table
    FILE_IDS = ["YOUR_DRIVE_FILE_ID_HERE"]  # Get from your notebook workspace
    
    print(f"🔍 Testing file retrieval...")
    print(f"   User ID: {USER_ID}")
    print(f"   File IDs: {FILE_IDS}")
    print()
    
    try:
        rag_service = get_rag_query_service()
        
        # Test retrieval
        chunks = await rag_service.retrieve_context(
            question="What is this document about?",
            user_id=USER_ID,
            selected_file_ids=FILE_IDS,
            top_k=5
        )
        
        print(f"✅ Retrieved {len(chunks)} chunks")
        
        if chunks:
            print("\n📄 First chunk preview:")
            print(f"   File: {chunks[0].file_name}")
            print(f"   Page: {chunks[0].page_number}")
            print(f"   Content: {chunks[0].content[:200]}...")
        else:
            print("\n❌ No chunks found!")
            print("\nPossible reasons:")
            print("1. Files not indexed in Pinecone")
            print("2. Wrong file IDs")
            print("3. Wrong user ID")
            print("4. Pinecone namespace issue")
            
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    print("=" * 60)
    print("NOTEBOOK AI DEBUG TEST")
    print("=" * 60)
    print()
    print("INSTRUCTIONS:")
    print("1. Edit this file and replace USER_ID and FILE_IDS")
    print("2. Get USER_ID from Supabase users table")
    print("3. Get FILE_IDS from your notebook workspace (driveFileId)")
    print("4. Run: uv run python backend/test_notebook_ai_debug.py")
    print()
    print("=" * 60)
    print()
    
    asyncio.run(test_file_retrieval())
