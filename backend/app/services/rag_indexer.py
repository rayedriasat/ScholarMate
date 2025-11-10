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
from langchain_huggingface import HuggingFaceEmbeddings

from .pinecone_service import get_pinecone_service
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
        logger.info("Initializing RAG indexer services...")
        
        try:
            self.pinecone_service = get_pinecone_service()
            logger.info("Pinecone service initialized")
        except Exception as e:
            logger.error(f"Failed to initialize Pinecone service: {str(e)}")
            raise
        
        try:
            self.drive_service = get_drive_service()
            logger.info("Drive service initialized")
        except Exception as e:
            logger.error(f"Failed to initialize Drive service: {str(e)}")
            raise
        
        try:
            self.supabase_service = get_supabase_service()
            logger.info("Supabase service initialized")
        except Exception as e:
            logger.error(f"Failed to initialize Supabase service: {str(e)}")
            raise
        
        # Initialize text splitter with smaller chunks for memory efficiency
        # Smaller chunks = less memory usage during embedding generation
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=400,  # Further reduced to minimize memory
            chunk_overlap=40,  # Reduced overlap
            length_function=len,
            separators=["\n\n", "\n", " ", ""]
        )
        
        # Batch sizes for processing (configurable via env vars for memory tuning)
        # CRITICAL: Keep these small to avoid memory spikes on Render free tier (512MB)
        self.BATCH_SIZE = int(os.getenv("EMBEDDING_BATCH_SIZE", "3"))  # Chunks per batch - REDUCED
        self.PAGE_BATCH_SIZE = int(os.getenv("PDF_PAGE_BATCH_SIZE", "2"))  # Pages per batch - REDUCED
        self.PINECONE_BATCH_SIZE = int(os.getenv("PINECONE_BATCH_SIZE", "25"))  # Pinecone upsert batch - REDUCED
        
        logger.info(f"Text splitter initialized: chunk_size=400, embedding_batch={self.BATCH_SIZE}, page_batch={self.PAGE_BATCH_SIZE}, pinecone_batch={self.PINECONE_BATCH_SIZE} (memory-optimized)")
        
        # Initialize GROQ chat model
        groq_api_key = os.getenv("GROQ_API_KEY")
        if not groq_api_key:
            logger.error("GROQ_API_KEY not found in environment")
            raise ValueError("GROQ_API_KEY is required")
        
        try:
            self.groq_chat = ChatGroq(
                api_key=groq_api_key,
                model="llama-3.3-70b-versatile"
            )
            logger.info("GROQ chat model initialized")
        except Exception as e:
            logger.error(f"Failed to initialize GROQ: {str(e)}")
            raise
        
        # Lazy-load embeddings to avoid blocking startup
        self._embeddings = None
        local_model_path = os.path.join(os.path.dirname(__file__), "..", "..", "models", "all-MiniLM-L6-v2")
        
        # Check if local model exists, otherwise fall back to downloading
        if os.path.exists(local_model_path):
            self._embedding_model = local_model_path
            logger.info(f"Will use local embedding model from: {local_model_path}")
        else:
            self._embedding_model = os.getenv("EMBEDDING_MODEL", "sentence-transformers/all-MiniLM-L6-v2")
            logger.info(f"Will download embedding model on first use: {self._embedding_model}")
        
        logger.info("RAG Indexer initialized with chunk_size=1000, chunk_overlap=200 (embeddings will load on first use)")
    
    @property
    def embeddings(self):
        """Lazy-load embeddings model on first access."""
        if self._embeddings is None:
            logger.info(f"Loading embedding model: {self._embedding_model}")
            try:
                # Check for HuggingFace token and authenticate
                hf_token = os.getenv("HUGGINGFACEHUB_API_TOKEN")
                if hf_token:
                    logger.info("Authenticating with HuggingFace Hub")
                    try:
                        from huggingface_hub import login
                        login(token=hf_token)
                        logger.info("Successfully authenticated with HuggingFace Hub")
                    except Exception as e:
                        logger.warning(f"Failed to login to HuggingFace Hub: {e}")
                else:
                    logger.warning("No HUGGINGFACEHUB_API_TOKEN found - you may hit rate limits. Get token from: https://huggingface.co/settings/tokens")
                
                # Prepare model kwargs
                model_kwargs = {'device': 'cpu'}
                
                # Initialize embeddings
                self._embeddings = HuggingFaceEmbeddings(
                    model_name=self._embedding_model,
                    model_kwargs=model_kwargs,
                    encode_kwargs={'normalize_embeddings': True}
                )
                logger.info("HuggingFace embeddings loaded successfully")
            except Exception as e:
                logger.error(f"Failed to load HuggingFace embeddings: {str(e)}")
                raise
        return self._embeddings
    
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
        ULTRA memory-optimized: processes pages one at a time, immediate cleanup.
        
        Args:
            pdf_bytes: PDF file bytes
            file_id: File identifier
            file_name: File name for metadata
            
        Returns:
            List of LangChain Document objects with metadata
        """
        import tempfile
        import gc
        
        try:
            # Save PDF bytes to temporary file for PyPDFLoader
            with tempfile.NamedTemporaryFile(mode='wb', suffix='.pdf', delete=False) as temp_file:
                temp_path = temp_file.name
                temp_file.write(pdf_bytes)
            
            # Clear pdf_bytes from memory immediately
            del pdf_bytes
            gc.collect()
            
            # Load PDF using LangChain PyPDFLoader
            loader = PyPDFLoader(temp_path)
            pages = loader.load()
            
            # Clean up temp file immediately
            os.remove(temp_path)
            
            logger.info(f"Extracted {len(pages)} pages from {file_name}")
            
            # Split documents into chunks
            # Process in VERY small batches to avoid memory spikes
            all_chunks = []
            for i in range(0, len(pages), self.PAGE_BATCH_SIZE):
                page_batch = pages[i:i+self.PAGE_BATCH_SIZE]
                batch_chunks = self.text_splitter.split_documents(page_batch)
                all_chunks.extend(batch_chunks)
                
                # Clear batch from memory immediately
                del page_batch
                del batch_chunks
                gc.collect()
                
                # Small delay to allow GC to complete
                await asyncio.sleep(0.05)
                
                logger.debug(f"Processed pages {i+1}-{min(i+self.PAGE_BATCH_SIZE, len(pages))} of {len(pages)}")
            
            # Clear pages from memory
            del pages
            gc.collect()
            
            # Add file metadata to each chunk
            total_chunks = len(all_chunks)
            for i, chunk in enumerate(all_chunks):
                # Extract page number from source metadata
                page_number = chunk.metadata.get("page", 0)
                
                # Update metadata
                chunk.metadata.update({
                    "file_id": file_id,
                    "file_name": file_name,
                    "chunk_index": i,
                    "total_chunks": total_chunks,
                    "page_number": page_number,
                    "timestamp": datetime.utcnow().isoformat()
                })
            
            logger.info(f"Created {total_chunks} chunks from {file_name} (ultra memory-optimized)")
            return all_chunks
            
        except Exception as e:
            logger.error(f"Failed to extract and chunk text: {str(e)}")
            raise ValueError(f"Text extraction failed: {str(e)}")
    
    async def generate_embeddings(
        self,
        documents: List[Document],
        batch_size: int = None
    ) -> List[List[float]]:
        """
        Generate embeddings using HuggingFace sentence-transformers.
        ULTRA memory-optimized: processes in tiny batches with aggressive cleanup.
        
        Args:
            documents: List of LangChain Document objects
            batch_size: Number of documents to process at once (default: self.BATCH_SIZE)
            
        Returns:
            List of embedding vectors
        """
        import gc
        
        try:
            if batch_size is None:
                batch_size = self.BATCH_SIZE
            
            # Extract text from documents
            texts = [doc.page_content for doc in documents]
            
            logger.info(f"Generating embeddings for {len(documents)} documents in batches of {batch_size}")
            
            # Process in TINY batches to avoid memory spikes
            all_embeddings = []
            for i in range(0, len(texts), batch_size):
                batch_texts = texts[i:i+batch_size]
                
                # Generate embeddings for this batch
                batch_embeddings = self.embeddings.embed_documents(batch_texts)
                all_embeddings.extend(batch_embeddings)
                
                # Aggressive memory cleanup
                del batch_texts
                del batch_embeddings
                gc.collect()
                
                logger.debug(f"Generated embeddings for batch {i//batch_size + 1}/{(len(texts) + batch_size - 1)//batch_size}")
                
                # Longer delay to allow complete garbage collection
                await asyncio.sleep(0.2)
            
            # Final cleanup
            del texts
            gc.collect()
            
            logger.info(f"Generated {len(all_embeddings)} embeddings (ultra memory-optimized)")
            return all_embeddings
            
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
        Store embeddings in user-specific Pinecone namespace.
        ULTRA memory-optimized: sequential processing with aggressive cleanup.
        
        Args:
            documents: List of LangChain Document objects
            user_id: User UUID
            file_id: File identifier
            job_id: Job ID for progress tracking
        """
        import gc
        
        try:
            # Safety check: don't try to store empty documents
            if not documents or len(documents) == 0:
                logger.warning(f"Attempted to store 0 documents for file {file_id} - skipping")
                return
            
            total_chunks = len(documents)
            logger.info(f"Storing {total_chunks} documents in batches of {self.BATCH_SIZE} (ultra memory-optimized)")
            
            # Process and store in TINY batches to minimize memory usage
            for i in range(0, total_chunks, self.BATCH_SIZE):
                batch_docs = documents[i:i+self.BATCH_SIZE]
                batch_size = len(batch_docs)
                
                # Generate embeddings for this batch only
                batch_embeddings = await self.generate_embeddings(batch_docs, batch_size=batch_size)
                
                # Prepare data for Pinecone
                batch_texts = [doc.page_content for doc in batch_docs]
                batch_metadatas = [doc.metadata for doc in batch_docs]
                batch_ids = [f"{file_id}_chunk_{i+j}" for j in range(batch_size)]
                
                # Store this batch in user's Pinecone namespace with smaller sub-batches
                await self._store_to_pinecone_in_batches(
                    user_id=user_id,
                    documents=batch_texts,
                    metadatas=batch_metadatas,
                    ids=batch_ids,
                    embeddings=batch_embeddings
                )
                
                # Update job progress
                chunks_processed = min(i + self.BATCH_SIZE, total_chunks)
                await self._update_job_progress(
                    job_id=job_id,
                    chunks_processed=chunks_processed,
                    total_chunks=total_chunks
                )
                
                # Aggressive memory cleanup
                del batch_docs
                del batch_embeddings
                del batch_texts
                del batch_metadatas
                del batch_ids
                gc.collect()
                
                logger.info(f"Stored batch {i//self.BATCH_SIZE + 1}/{(total_chunks + self.BATCH_SIZE - 1)//self.BATCH_SIZE} ({chunks_processed}/{total_chunks} chunks)")
                
                # Longer delay between batches to allow complete garbage collection
                await asyncio.sleep(0.3)
            
            # Final cleanup
            del documents
            gc.collect()
            
            logger.info(f"Stored all {total_chunks} documents for file {file_id} (ultra memory-optimized)")
            
        except Exception as e:
            logger.error(f"Failed to store embeddings: {str(e)}")
            raise ValueError(f"Embedding storage failed: {str(e)}")
    
    async def _store_to_pinecone_in_batches(
        self,
        user_id: str,
        documents: List[str],
        metadatas: List[Dict[str, Any]],
        ids: List[str],
        embeddings: List[List[float]]
    ) -> None:
        """
        Store to Pinecone in smaller sub-batches to avoid memory spikes.
        
        Args:
            user_id: User UUID
            documents: List of document texts
            metadatas: List of metadata dicts
            ids: List of unique document IDs
            embeddings: Pre-computed embeddings
        """
        import gc
        
        # Store in smaller sub-batches
        for i in range(0, len(documents), self.PINECONE_BATCH_SIZE):
            sub_docs = documents[i:i+self.PINECONE_BATCH_SIZE]
            sub_metas = metadatas[i:i+self.PINECONE_BATCH_SIZE]
            sub_ids = ids[i:i+self.PINECONE_BATCH_SIZE]
            sub_embeddings = embeddings[i:i+self.PINECONE_BATCH_SIZE]
            
            # Store this sub-batch
            self.pinecone_service.add_documents(
                user_id=user_id,
                documents=sub_docs,
                metadatas=sub_metas,
                ids=sub_ids,
                embeddings=sub_embeddings
            )
            
            # Cleanup
            del sub_docs
            del sub_metas
            del sub_ids
            del sub_embeddings
            gc.collect()
            
            # Small delay
            await asyncio.sleep(0.1)
        
        logger.debug(f"Stored {len(documents)} documents to Pinecone in sub-batches of {self.PINECONE_BATCH_SIZE}")
    
    async def get_user_namespace(self, user_id: str) -> str:
        """
        Get user's Pinecone namespace.
        
        Args:
            user_id: User UUID
            
        Returns:
            Namespace string
        """
        return self.pinecone_service.get_user_namespace(user_id)
    

    
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
        try:
            logger.info("Initializing RAG indexer singleton...")
            _rag_indexer = RAGIndexer()
            logger.info("RAG indexer initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize RAG indexer: {str(e)}", exc_info=True)
            raise
    return _rag_indexer
