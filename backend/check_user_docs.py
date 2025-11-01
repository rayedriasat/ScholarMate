"""Check if user has documents indexed in ChromaDB"""
import sys
from app.services.chroma_service import get_chroma_service

def check_user_documents(user_id: str):
    """Check if user has documents in ChromaDB"""
    chroma_service = get_chroma_service()
    
    # Get collection stats
    stats = chroma_service.get_collection_stats(user_id)
    print(f"\nCollection Stats for user {user_id}:")
    print(f"  Collection Name: {stats['collection_name']}")
    print(f"  Document Count: {stats['document_count']}")
    
    if stats['document_count'] > 0:
        # Try to query some documents
        try:
            results = chroma_service.query_documents(
                user_id=user_id,
                query_texts=["test"],
                n_results=3
            )
            print(f"\n  Sample query returned {len(results['ids'][0])} results")
            
            if results['ids'] and len(results['ids'][0]) > 0:
                print("\n  Sample documents:")
                for i in range(min(3, len(results['ids'][0]))):
                    metadata = results['metadatas'][0][i]
                    print(f"    - File: {metadata.get('file_name', 'Unknown')}")
                    print(f"      Page: {metadata.get('page_number', 0)}")
                    print(f"      File ID: {metadata.get('file_id', 'Unknown')}")
        except Exception as e:
            print(f"\n  Error querying documents: {e}")
    else:
        print("\n  ⚠️  No documents indexed for this user!")
        print("  Please index some documents first using the indexing API.")

if __name__ == "__main__":
    if len(sys.argv) > 1:
        user_id = sys.argv[1]
    else:
        # Default to the Google user ID from the logs
        user_id = "111319857386978820359"
    
    check_user_documents(user_id)
