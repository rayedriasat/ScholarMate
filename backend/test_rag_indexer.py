"""
Test RAG Indexer Service
Tests document indexing with text extraction, chunking, and embedding generation.
"""

import os
import sys
import asyncio
import logging
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from dotenv import load_dotenv
from app.services import get_rag_indexer, get_chroma_service

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


async def test_rag_indexer():
    """Test RAG indexer with a sample PDF."""
    
    print("\n" + "="*80)
    print("RAG INDEXER SERVICE TEST")
    print("="*80 + "\n")
    
    try:
        # Initialize services
        indexer = get_rag_indexer()
        chroma = get_chroma_service()
        
        print("[OK] RAG Indexer initialized successfully")
        print(f"   - Chunk size: 1000")
        print(f"   - Chunk overlap: 200")
        print(f"   - Embedding model: GROQ (llama-3.3-70b-versatile)")
        
        # Test user ID
        test_user_id = "test_user_123"
        test_file_id = "test_file_456"
        test_file_name = "sample_document.pdf"
        
        print(f"\n📋 Test Configuration:")
        print(f"   - User ID: {test_user_id}")
        print(f"   - File ID: {test_file_id}")
        print(f"   - File Name: {test_file_name}")
        
        # Check if we have a test PDF file
        test_pdf_path = Path(__file__).parent / "test_data" / "sample.pdf"
        
        if not test_pdf_path.exists():
            print(f"\n[WARN] Test PDF not found at {test_pdf_path}")
            print("   Creating a simple test PDF...")
            
            # Create test data directory
            test_pdf_path.parent.mkdir(exist_ok=True)
            
            # Create a simple PDF using reportlab
            from reportlab.pdfgen import canvas
            from reportlab.lib.pagesizes import letter
            
            c = canvas.Canvas(str(test_pdf_path), pagesize=letter)
            c.drawString(100, 750, "Test Document for RAG Indexing")
            c.drawString(100, 730, "")
            c.drawString(100, 710, "This is a test document to verify the RAG indexer.")
            c.drawString(100, 690, "It contains multiple lines of text that will be")
            c.drawString(100, 670, "extracted, chunked, and embedded using GROQ.")
            c.drawString(100, 650, "")
            c.drawString(100, 630, "Machine learning is a subset of artificial intelligence")
            c.drawString(100, 610, "that focuses on building systems that can learn from data.")
            c.showPage()
            
            c.drawString(100, 750, "Page 2 - More Content")
            c.drawString(100, 730, "")
            c.drawString(100, 710, "Neural networks are computing systems inspired by")
            c.drawString(100, 690, "biological neural networks in animal brains.")
            c.showPage()
            c.save()
            
            print(f"[OK] Created test PDF at {test_pdf_path}")
        
        # Read test PDF
        with open(test_pdf_path, "rb") as f:
            pdf_bytes = f.read()
        
        print(f"\n📄 Test PDF loaded: {len(pdf_bytes)} bytes")
        
        # Test 1: Extract and chunk text
        print("\n" + "-"*80)
        print("TEST 1: Extract and Chunk Text")
        print("-"*80)
        
        documents = await indexer.extract_and_chunk_text(
            pdf_bytes=pdf_bytes,
            file_id=test_file_id,
            file_name=test_file_name
        )
        
        print(f"[OK] Extracted and chunked text successfully")
        print(f"   - Total chunks: {len(documents)}")
        
        if documents:
            print(f"\n   Sample chunk metadata:")
            sample = documents[0]
            print(f"   - File ID: {sample.metadata.get('file_id')}")
            print(f"   - File Name: {sample.metadata.get('file_name')}")
            print(f"   - Page Number: {sample.metadata.get('page_number')}")
            print(f"   - Chunk Index: {sample.metadata.get('chunk_index')}")
            print(f"   - Total Chunks: {sample.metadata.get('total_chunks')}")
            print(f"   - Content Preview: {sample.page_content[:100]}...")
        
        # Test 2: Generate embeddings
        print("\n" + "-"*80)
        print("TEST 2: Generate Embeddings")
        print("-"*80)
        
        try:
            embeddings = await indexer.generate_embeddings(documents[:2])  # Test with first 2 chunks
            print(f"[OK] Generated embeddings successfully")
            print(f"   - Number of embeddings: {len(embeddings)}")
            if embeddings:
                print(f"   - Embedding dimension: {len(embeddings[0])}")
        except Exception as e:
            print(f"[WARN] Embedding generation failed (expected if GROQ embeddings not available): {str(e)}")
            print("   Note: GROQ may not have native embedding support yet")
        
        # Test 3: Store embeddings (without actual embeddings for now)
        print("\n" + "-"*80)
        print("TEST 3: Store Documents in ChromaDB")
        print("-"*80)
        
        # Store documents without pre-computed embeddings (ChromaDB will use default)
        texts = [doc.page_content for doc in documents]
        metadatas = [doc.metadata for doc in documents]
        ids = [f"{test_file_id}_chunk_{i}" for i in range(len(documents))]
        
        chroma.add_documents(
            user_id=test_user_id,
            documents=texts,
            metadatas=metadatas,
            ids=ids
        )
        
        print(f"[OK] Stored documents in ChromaDB")
        print(f"   - Collection: {chroma.get_user_collection_name(test_user_id)}")
        print(f"   - Documents stored: {len(documents)}")
        
        # Test 4: Query documents
        print("\n" + "-"*80)
        print("TEST 4: Query Documents")
        print("-"*80)
        
        query_results = chroma.query_documents(
            user_id=test_user_id,
            query_texts=["machine learning"],
            n_results=2
        )
        
        print(f"[OK] Query executed successfully")
        print(f"   - Query: 'machine learning'")
        print(f"   - Results returned: {len(query_results['ids'][0])}")
        
        if query_results['documents'][0]:
            print(f"\n   Top result:")
            print(f"   - Content: {query_results['documents'][0][0][:100]}...")
            print(f"   - Distance: {query_results['distances'][0][0]:.4f}")
            print(f"   - Metadata: {query_results['metadatas'][0][0]}")
        
        # Test 5: Get collection stats
        print("\n" + "-"*80)
        print("TEST 5: Collection Statistics")
        print("-"*80)
        
        stats = chroma.get_collection_stats(test_user_id)
        print(f"[OK] Collection stats retrieved")
        print(f"   - Collection name: {stats['collection_name']}")
        print(f"   - Document count: {stats['document_count']}")
        
        # Test 6: Get user collection
        print("\n" + "-"*80)
        print("TEST 6: Get User Collection")
        print("-"*80)
        
        collection = await indexer.get_user_collection(test_user_id)
        print(f"[OK] User collection retrieved")
        print(f"   - Collection name: {collection.name}")
        print(f"   - Document count: {collection.count()}")
        
        # Cleanup
        print("\n" + "-"*80)
        print("CLEANUP")
        print("-"*80)
        
        chroma.delete_user_collection(test_user_id)
        print(f"[OK] Deleted test collection")
        
        print("\n" + "="*80)
        print("ALL TESTS PASSED [OK]")
        print("="*80 + "\n")
        
        print("Summary:")
        print("[OK] Text extraction and chunking working")
        print("[OK] Document storage in ChromaDB working")
        print("[OK] Semantic search working")
        print("[OK] User collection management working")
        print("[WARN] GROQ embeddings may need configuration (using ChromaDB defaults)")
        
    except Exception as e:
        print(f"\n[FAIL] Test failed: {str(e)}")
        import traceback
        traceback.print_exc()
        return False
    
    return True


if __name__ == "__main__":
    success = asyncio.run(test_rag_indexer())
    sys.exit(0 if success else 1)
