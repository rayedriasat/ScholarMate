"""
RAG Indexer Service with LangChain and GROQ.
Handles document indexing with text extraction, chunking, and embedding generation.
"""

import os
import io
import logging
import uuid
from typing import List, Dict, Any, Optional
from datetime import datetime

from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import PyPDFLoader
from langchain_core.documents import Document
from langchain_groq import ChatGroq

from .chroma_service import get_chroma_service
from .drive_service import get_drive_service
from .supabase_service import get_supabase_service

logger = logging.getLogger(__name__)


class RAGIndexer:
    """Service for indexing documents with LangChain and GROQ embeddings."""
    
    def __init__(self):
        """Initialize RAG indexer with required services."""
        self.chroma_service = get_chroma_service()
        self.drive_service = get_drive_service()
        self.supabase_service = get_supabase_service()
        
        # Initialize text splitter with specified parameters
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200,
            length_function=len,
            separators=["\n\n", "\n", " ", ""]
        )
        
        # Initialize GROQ chat model for embeddings
        # Note: GROQ doesn't have native embeddings yet, we'll use ChromaDB's default
        groq_api_key = os.getenv("GROQ_API_KEY")
        if not groq_api_key:
            raise ValueError("GROQ_API_KEY is required")
        
        self.groq_chat = ChatGroq(
            api_key=groq_api_key,
            model="llama-3.3-70b-versatile"
        )
        
        logger.info("RAG Indexer initialized with chunk_size=1000, chunk_overlap=200")
    
    async def index_file(
        self,
        file_id: str,
        user_id: str,
        file_name: Optional[str] = None
    ) -> str:
        """
        Start indexing job for a file.
        
        Args:
            file_id: Google Drive file ID
            user_id: User UUID
            file_name: Optional file name for metadata
            
        Returns:
            Job ID for tracking indexing progress
            
        Raises:
            ValueError: If file cannot be indexed
        """
        job_id = str(uuid.uuid4())
        
        try:
            logger.info(f"Starting indexing job {job_id} for file {file_id}, user {user_id}")
            
            # Create job record in database
            await self._create_indexing_job(
                job_id=job_id,
                user_id=user_id,
                file_id=file_id,
                status="pending"
            )
            
            # Fetch file from Google Drive (source of truth)
            logger.info(f"Fetching file {file_id} from Google Drive")
            file_bytes = await self.drive_service.get_file_bytes(file_id, user_id)
            
            # Get file metadata if not provided
            if not file_name:
                metadata = await self.drive_service.get_file_metadata(file_id, user_id)
                file_name = metadata.get("name", f"file_{file_id}")
            
            # Update job status to processing
            await self._update_job_status(job_id, "processing")
            
            # Extract and chunk text
            logger.info(f"Extracting and chunking text from {file_name}")
            documents = await self.extract_and_chunk_text(file_bytes, file_id, file_name)
            
            # Update total chunks
            await self._update_job_progress(
                job_id=job_id,
                chunks_processed=0,
                total_chunks=len(documents)
            )
            
            # Generate embeddings and store
            logger.info(f"Generating embeddings for {len(documents)} chunks")
            await self.store_embeddings(
                documents=documents,
                user_id=user_id,
                file_id=file_id,
                job_id=job_id
            )
            
            # Update job status to completed
            await self._update_job_status(job_id, "completed")
            
            logger.info(f"Indexing job {job_id} completed successfully")
            return job_id
            
        except Exception as e:
            logger.error(f"Indexing job {job_id} failed: {str(e)}")
            await self._update_job_status(
                job_id=job_id,
                status="failed",
                error_message=str(e)
            )
            raise ValueError(f"Failed to index file: {str(e)}")
    
    async def extract_and_chunk_text(
        self,
        pdf_bytes: bytes,
        file_id: str,
        file_name: str
    ) -> List[Document]:
        """
        Extract text from PDF and chunk using LangChain.
        
        Args:
            pdf_bytes: PDF file bytes
            file_id: File identifier
            file_name: File name for metadata
            
        Returns:
            List of LangChain Document objects with metadata
        """
        import tempfile
        
        try:
            # Save PDF bytes to temporary file for PyPDFLoader
            with tempfile.NamedTemporaryFile(mode='wb', suffix='.pdf', delete=False) as temp_file:
                temp_path = temp_file.name
                temp_file.write(pdf_bytes)
            
            # Load PDF using LangChain PyPDFLoader
            loader = PyPDFLoader(temp_path)
            pages = loader.load()
            
            # Clean up temp file
            os.remove(temp_path)
            
            logger.info(f"Extracted {len(pages)} pages from {file_name}")
            
            # Split documents into chunks
            chunks = self.text_splitter.split_documents(pages)
            
            # Add file metadata to each chunk
            for i, chunk in enumerate(chunks):
                # Extract page number from source metadata
                page_number = chunk.metadata.get("page", 0)
                
                # Update metadata
                chunk.metadata.update({
                    "file_id": file_id,
                    "file_name": file_name,
                    "chunk_index": i,
                    "total_chunks": len(chunks),
                    "page_number": page_number,
                    "timestamp": datetime.utcnow().isoformat()
                })
            
            logger.info(f"Created {len(chunks)} chunks from {file_name}")
            return chunks
            
        except Exception as e:
            logger.error(f"Failed to extract and chunk text: {str(e)}")
            raise ValueError(f"Text extraction failed: {str(e)}")
    
    async def generate_embeddings(
        self,
        documents: List[Document]
    ) -> Optional[List[List[float]]]:
        """
        Generate embeddings using GROQ via LangChain.
        
        Note: GROQ doesn't have native embeddings yet, so we return None
        and let ChromaDB use its default embedding function.
        
        Args:
            documents: List of LangChain Document objects
            
        Returns:
            None (ChromaDB will use default embeddings)
        """
        try:
            # GROQ doesn't have native embeddings yet
            # ChromaDB will use its default embedding function
            logger.info(f"Using ChromaDB default embeddings for {len(documents)} documents")
            return None
            
        except Exception as e:
            logger.error(f"Failed to generate embeddings: {str(e)}")
            raise ValueError(f"Embedding generation failed: {str(e)}")
    
    async def store_embeddings(
        self,
        documents: List[Document],
        user_id: str,
        file_id: str,
        job_id: str
    ) -> None:
        """
        Store embeddings in user-specific ChromaDB collection.
        
        Args:
            documents: List of LangChain Document objects
            user_id: User UUID
            file_id: File identifier
            job_id: Job ID for progress tracking
        """
        try:
            # Generate embeddings (returns None for ChromaDB default)
            embeddings = await self.generate_embeddings(documents)
            
            # Prepare data for ChromaDB
            texts = [doc.page_content for doc in documents]
            metadatas = [doc.metadata for doc in documents]
            ids = [f"{file_id}_chunk_{i}" for i in range(len(documents))]
            
            # Store in user's ChromaDB collection
            # If embeddings is None, ChromaDB will use its default embedding function
            self.chroma_service.add_documents(
                user_id=user_id,
                documents=texts,
                metadatas=metadatas,
                ids=ids,
                embeddings=embeddings
            )
            
            # Update job progress
            await self._update_job_progress(
                job_id=job_id,
                chunks_processed=len(documents),
                total_chunks=len(documents)
            )
            
            logger.info(f"Stored {len(documents)} documents for file {file_id}")
            
        except Exception as e:
            logger.error(f"Failed to store embeddings: {str(e)}")
            raise ValueError(f"Embedding storage failed: {str(e)}")
    
    async def get_user_collection(self, user_id: str):
        """
        Get or create user's vector store.
        
        Args:
            user_id: User UUID
            
        Returns:
            ChromaDB Collection object
        """
        return self.chroma_service.get_or_create_user_collection(user_id)
    
    async def reindex_file(
        self,
        file_id: str,
        user_id: str,
        file_name: Optional[str] = None
    ) -> str:
        """
        Reindex a file (delete old embeddings and create new ones).
        
        Args:
            file_id: Google Drive file ID
            user_id: User UUID
            file_name: Optional file name
            
        Returns:
            Job ID for tracking
        """
        try:
            logger.info(f"Reindexing file {file_id} for user {user_id}")
            
            # Delete existing embeddings for this file
            self.chroma_service.delete_documents_by_file(user_id, file_id)
            
            # Index the file again
            job_id = await self.index_file(file_id, user_id, file_name)
            
            logger.info(f"Reindexing job {job_id} started for file {file_id}")
            return job_id
            
        except Exception as e:
            logger.error(f"Failed to reindex file {file_id}: {str(e)}")
            raise ValueError(f"Reindexing failed: {str(e)}")
    
    # Helper methods for job tracking
    
    async def _create_indexing_job(
        self,
        job_id: str,
        user_id: str,
        file_id: str,
        status: str
    ) -> None:
        """Create indexing job record in database."""
        # TODO: Implement when ingestion_jobs table is ready
        logger.info(f"Created job {job_id} with status {status}")
        pass
    
    async def _update_job_status(
        self,
        job_id: str,
        status: str,
        error_message: Optional[str] = None
    ) -> None:
        """Update job status in database."""
        # TODO: Implement when ingestion_jobs table is ready
        logger.info(f"Updated job {job_id} status to {status}")
        if error_message:
            logger.error(f"Job {job_id} error: {error_message}")
        pass
    
    async def _update_job_progress(
        self,
        job_id: str,
        chunks_processed: int,
        total_chunks: int
    ) -> None:
        """Update job progress in database."""
        # TODO: Implement when ingestion_jobs table is ready
        progress = (chunks_processed / total_chunks * 100) if total_chunks > 0 else 0
        logger.info(f"Job {job_id} progress: {chunks_processed}/{total_chunks} ({progress:.1f}%)")
        pass


# Singleton instance
_rag_indexer: Optional[RAGIndexer] = None


def get_rag_indexer() -> RAGIndexer:
    """Get or create RAG indexer singleton."""
    global _rag_indexer
    if _rag_indexer is None:
        _rag_indexer = RAGIndexer()
    return _rag_indexer
