"""
RAG Indexer Service with LangChain and GROQ.
Handles document indexing with text extraction, chunking, and embedding generation.
"""

import os
import io
import logging
import uuid
import asyncio
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

# Configuration for retry logic
MAX_RETRIES = 3
INITIAL_RETRY_DELAY = 1  # seconds
MAX_RETRY_DELAY = 60  # seconds


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
        Start indexing job for a file (creates job record only).
        Actual processing happens in background via process_indexing_job.
        
        Args:
            file_id: Google Drive file ID
            user_id: User UUID
            file_name: Optional file name for metadata
            
        Returns:
            Job ID for tracking indexing progress
            
        Raises:
            ValueError: If job cannot be created
        """
        job_id = str(uuid.uuid4())
        
        try:
            logger.info(f"Creating indexing job {job_id} for file {file_id}, user {user_id}")
            
            # Create job record in database with pending status
            await self._create_indexing_job(
                job_id=job_id,
                user_id=user_id,
                file_id=file_id,
                status="pending",
                file_name=file_name
            )
            
            logger.info(f"Indexing job {job_id} created successfully")
            return job_id
            
        except Exception as e:
            logger.error(f"Failed to create indexing job: {str(e)}")
            raise ValueError(f"Failed to create indexing job: {str(e)}")
    
    async def process_indexing_job(
        self,
        job_id: str,
        retry_count: int = 0
    ) -> None:
        """
        Process an indexing job in the background with retry logic.
        This method runs asynchronously and handles all the heavy lifting.
        
        Args:
            job_id: Job ID to process
            retry_count: Current retry attempt (for exponential backoff)
        """
        try:
            logger.info(f"Processing indexing job {job_id} (attempt {retry_count + 1}/{MAX_RETRIES + 1})")
            
            # Get job details from database
            job_data = await self.get_job_status(job_id)
            if not job_data:
                logger.error(f"Job {job_id} not found in database")
                return
            
            user_id = job_data["user_id"]
            file_id = job_data["file_id"]
            
            # Update job status to processing
            await self._update_job_status(job_id, "processing")
            
            # Fetch file from Google Drive (source of truth)
            logger.info(f"Fetching file {file_id} from Google Drive")
            file_bytes = await self.drive_service.get_file_bytes(file_id, user_id)
            
            # Get file metadata
            metadata = await self.drive_service.get_file_metadata(file_id, user_id)
            file_name = metadata.get("name", f"file_{file_id}")
            
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
            
            # Handle empty documents (PDF with no extractable text)
            if len(documents) == 0:
                logger.warning(f"No chunks created from {file_name} - PDF may be empty or contain only images")
                await self._update_job_status(
                    job_id,
                    "completed",
                    error_message="No text content extracted from PDF. The file may be empty or contain only images."
                )
                logger.info(f"Indexing job {job_id} completed with no content")
                return
            
            await self.store_embeddings(
                documents=documents,
                user_id=user_id,
                file_id=file_id,
                job_id=job_id
            )
            
            # Update job status to completed
            await self._update_job_status(job_id, "completed")
            
            logger.info(f"Indexing job {job_id} completed successfully")
            
        except Exception as e:
            logger.error(f"Indexing job {job_id} failed (attempt {retry_count + 1}): {str(e)}")
            
            # Implement exponential backoff retry logic
            if retry_count < MAX_RETRIES:
                # Calculate delay with exponential backoff
                delay = min(INITIAL_RETRY_DELAY * (2 ** retry_count), MAX_RETRY_DELAY)
                logger.info(f"Retrying job {job_id} in {delay} seconds (attempt {retry_count + 2}/{MAX_RETRIES + 1})")
                
                # Update job metadata with retry info
                await self._update_job_retry_info(job_id, retry_count + 1, str(e))
                
                # Schedule retry after delay
                await asyncio.sleep(delay)
                await self.process_indexing_job(job_id, retry_count + 1)
            else:
                # Max retries exceeded, mark as failed
                logger.error(f"Job {job_id} failed after {MAX_RETRIES + 1} attempts")
                await self._update_job_status(
                    job_id=job_id,
                    status="failed",
                    error_message=f"Failed after {MAX_RETRIES + 1} attempts: {str(e)}"
                )
    
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
            # Safety check: don't try to store empty documents
            if not documents or len(documents) == 0:
                logger.warning(f"Attempted to store 0 documents for file {file_id} - skipping")
                return
            
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
    

    
    # Helper methods for job tracking
    
    async def _create_indexing_job(
        self,
        job_id: str,
        user_id: str,
        file_id: str,
        status: str,
        file_name: Optional[str] = None
    ) -> None:
        """Create indexing job record in database."""
        try:
            # Convert Google user ID to Supabase UUID if needed
            supabase_user_id = await self._get_or_create_user_uuid(user_id)
            
            # First, get or create the file record in Supabase
            # We need the UUID file_id, not the Drive file_id
            file_response = self.supabase_service.client.table("files").select("id").eq("user_id", supabase_user_id).eq("drive_file_id", file_id).execute()
            
            if not file_response.data or len(file_response.data) == 0:
                # File doesn't exist in Supabase yet, create it
                file_data = {
                    "user_id": supabase_user_id,
                    "drive_file_id": file_id,
                    "name": file_name or f"file_{file_id}",
                    "mime_type": "application/pdf",
                    "is_folder": False
                }
                file_response = self.supabase_service.client.table("files").insert(file_data).execute()
                supabase_file_id = file_response.data[0]["id"]
            else:
                supabase_file_id = file_response.data[0]["id"]
            
            job_data = {
                "user_id": supabase_user_id,
                "file_id": supabase_file_id,
                "job_type": "rag_indexing",
                "status": status,
                "progress_percent": 0,
                "metadata": {
                    "job_id": job_id,
                    "drive_file_id": file_id,
                    "google_user_id": user_id,  # Store original Google ID for reference
                    "chunks_processed": 0,
                    "total_chunks": None,
                    "retry_count": 0,
                    "last_error": None
                },
                "started_at": None,
                "completed_at": None
            }
            
            self.supabase_service.client.table("ingestion_jobs").insert(job_data).execute()
            logger.info(f"Created job {job_id} with status {status}")
            
        except Exception as e:
            logger.error(f"Failed to create job record: {str(e)}")
            raise  # Raise error since job creation is critical
    
    async def _get_or_create_user_uuid(self, google_user_id: str) -> str:
        """
        Get Supabase UUID for a Google user ID, or create user if doesn't exist.
        
        Args:
            google_user_id: Google user ID (numeric string)
            
        Returns:
            Supabase user UUID
        """
        try:
            # Try to find existing user by google_sub
            user_response = self.supabase_service.client.table("users").select("id").eq("google_sub", google_user_id).execute()
            
            if user_response.data and len(user_response.data) > 0:
                return user_response.data[0]["id"]
            
            # User doesn't exist, create a minimal user record
            # Note: In production, this should be created during authentication
            logger.warning(f"User with google_sub {google_user_id} not found, creating minimal record")
            user_data = {
                "google_sub": google_user_id,
                "email": f"user_{google_user_id}@temp.local",  # Placeholder email
                "name": f"User {google_user_id}"
            }
            create_response = self.supabase_service.client.table("users").insert(user_data).execute()
            return create_response.data[0]["id"]
            
        except Exception as e:
            logger.error(f"Failed to get/create user UUID: {str(e)}")
            raise ValueError(f"Failed to resolve user ID: {str(e)}")
    
    async def _update_job_status(
        self,
        job_id: str,
        status: str,
        error_message: Optional[str] = None
    ) -> None:
        """Update job status in database."""
        try:
            # Find the job by metadata->job_id
            job_response = self.supabase_service.client.table("ingestion_jobs").select("*").filter("metadata->>job_id", "eq", job_id).execute()
            
            if not job_response.data or len(job_response.data) == 0:
                logger.warning(f"Job {job_id} not found in database")
                return
            
            db_job_id = job_response.data[0]["id"]
            
            update_data = {
                "status": status,
                "updated_at": datetime.utcnow().isoformat()
            }
            
            if status == "processing":
                update_data["started_at"] = datetime.utcnow().isoformat()
            elif status in ["completed", "failed"]:
                update_data["completed_at"] = datetime.utcnow().isoformat()
                if status == "completed":
                    update_data["progress_percent"] = 100
            
            if error_message:
                update_data["error_message"] = error_message
            
            self.supabase_service.client.table("ingestion_jobs").update(update_data).eq("id", db_job_id).execute()
            logger.info(f"Updated job {job_id} status to {status}")
            
            if error_message:
                logger.error(f"Job {job_id} error: {error_message}")
                
        except Exception as e:
            logger.error(f"Failed to update job status: {str(e)}")
            # Don't fail the indexing if job tracking fails
    
    async def _update_job_progress(
        self,
        job_id: str,
        chunks_processed: int,
        total_chunks: int
    ) -> None:
        """Update job progress in database."""
        try:
            progress = int((chunks_processed / total_chunks * 100)) if total_chunks > 0 else 0
            
            # Find the job by metadata->job_id
            job_response = self.supabase_service.client.table("ingestion_jobs").select("*").filter("metadata->>job_id", "eq", job_id).execute()
            
            if not job_response.data or len(job_response.data) == 0:
                logger.warning(f"Job {job_id} not found in database")
                return
            
            db_job_id = job_response.data[0]["id"]
            current_metadata = job_response.data[0].get("metadata", {})
            
            # Update metadata with chunks info
            updated_metadata = {
                **current_metadata,
                "chunks_processed": chunks_processed,
                "total_chunks": total_chunks
            }
            
            update_data = {
                "progress_percent": progress,
                "metadata": updated_metadata,
                "updated_at": datetime.utcnow().isoformat()
            }
            
            self.supabase_service.client.table("ingestion_jobs").update(update_data).eq("id", db_job_id).execute()
            logger.info(f"Job {job_id} progress: {chunks_processed}/{total_chunks} ({progress}%)")
            
        except Exception as e:
            logger.error(f"Failed to update job progress: {str(e)}")
            # Don't fail the indexing if job tracking fails
    
    async def _update_job_retry_info(
        self,
        job_id: str,
        retry_count: int,
        error_message: str
    ) -> None:
        """Update job retry information in database."""
        try:
            # Find the job by metadata->job_id
            job_response = self.supabase_service.client.table("ingestion_jobs").select("*").filter("metadata->>job_id", "eq", job_id).execute()
            
            if not job_response.data or len(job_response.data) == 0:
                logger.warning(f"Job {job_id} not found in database")
                return
            
            db_job_id = job_response.data[0]["id"]
            current_metadata = job_response.data[0].get("metadata", {})
            
            # Update metadata with retry info
            updated_metadata = {
                **current_metadata,
                "retry_count": retry_count,
                "last_error": error_message
            }
            
            update_data = {
                "metadata": updated_metadata,
                "updated_at": datetime.utcnow().isoformat()
            }
            
            self.supabase_service.client.table("ingestion_jobs").update(update_data).eq("id", db_job_id).execute()
            logger.info(f"Job {job_id} retry info updated: attempt {retry_count}")
            
        except Exception as e:
            logger.error(f"Failed to update job retry info: {str(e)}")
            # Don't fail the indexing if job tracking fails
    
    async def get_job_status(self, job_id: str) -> Optional[Dict[str, Any]]:
        """
        Get indexing job status from database.
        
        Args:
            job_id: Job ID to query
            
        Returns:
            Job status dict or None if not found
        """
        try:
            # Find the job by metadata->job_id
            response = self.supabase_service.client.table("ingestion_jobs").select("*").filter("metadata->>job_id", "eq", job_id).execute()
            
            if response.data and len(response.data) > 0:
                job = response.data[0]
                metadata = job.get("metadata", {})
                
                # Extract chunks info from metadata
                chunks_processed = metadata.get("chunks_processed", 0)
                total_chunks = metadata.get("total_chunks")
                drive_file_id = metadata.get("drive_file_id", "")
                
                # Return formatted response matching the JobStatus model
                return {
                    "job_id": job_id,
                    "user_id": job["user_id"],
                    "file_id": drive_file_id,  # Return Drive file ID, not Supabase UUID
                    "status": job["status"],
                    "chunks_processed": chunks_processed,
                    "total_chunks": total_chunks,
                    "progress_percentage": float(job.get("progress_percent", 0)),
                    "error_message": job.get("error_message"),
                    "started_at": job.get("started_at"),
                    "completed_at": job.get("completed_at"),
                    "created_at": job["created_at"]
                }
            
            return None
            
        except Exception as e:
            logger.error(f"Failed to get job status: {str(e)}")
            return None
    
    async def list_user_jobs(self, user_id: str) -> list[Dict[str, Any]]:
        """
        List all indexing jobs for a user.
        
        Args:
            user_id: User ID (Google ID or Supabase UUID)
            
        Returns:
            List of job status dicts
        """
        try:
            # Convert Google user ID to Supabase UUID if needed
            supabase_user_id = await self._get_or_create_user_uuid(user_id)
            
            response = self.supabase_service.client.table("ingestion_jobs").select("*").eq("user_id", supabase_user_id).eq("job_type", "rag_indexing").order("created_at", desc=True).execute()
            
            jobs = []
            for job in response.data:
                metadata = job.get("metadata", {})
                
                # Extract chunks info from metadata
                chunks_processed = metadata.get("chunks_processed", 0)
                total_chunks = metadata.get("total_chunks")
                job_id = metadata.get("job_id", str(job["id"]))
                drive_file_id = metadata.get("drive_file_id", "")
                
                # Return formatted response matching the JobStatus model
                jobs.append({
                    "job_id": job_id,
                    "user_id": job["user_id"],
                    "file_id": drive_file_id,  # Return Drive file ID, not Supabase UUID
                    "status": job["status"],
                    "chunks_processed": chunks_processed,
                    "total_chunks": total_chunks,
                    "progress_percentage": float(job.get("progress_percent", 0)),
                    "error_message": job.get("error_message"),
                    "started_at": job.get("started_at"),
                    "completed_at": job.get("completed_at"),
                    "created_at": job["created_at"]
                })
            
            return jobs
            
        except Exception as e:
            logger.error(f"Failed to list user jobs: {str(e)}")
            return []


# Singleton instance
_rag_indexer: Optional[RAGIndexer] = None


def get_rag_indexer() -> RAGIndexer:
    """Get or create RAG indexer singleton."""
    global _rag_indexer
    if _rag_indexer is None:
        _rag_indexer = RAGIndexer()
    return _rag_indexer
