"""
RAG Query Service with LangChain and GROQ.
Handles semantic search and question answering with source filtering and citations.
"""

import os
import logging
from typing import List, Dict, Any, Optional
from datetime import datetime

from langchain_groq import ChatGroq
from langchain_core.prompts import PromptTemplate
from langchain_core.documents import Document
from langchain_community.embeddings import HuggingFaceEmbeddings

from .pinecone_service import get_pinecone_service
from .groq_service import get_groq_service
from .supabase_service import get_supabase_service

logger = logging.getLogger(__name__)


class Citation:
    """Citation data structure for source references."""
    
    def __init__(
        self,
        file_id: str,
        file_name: str,
        page_number: int,
        snippet: str = ""
    ):
        self.file_id = file_id
        self.file_name = file_name
        self.page_number = page_number
        self.snippet = snippet
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert citation to dictionary."""
        return {
            "file_id": self.file_id,
            "file_name": self.file_name,
            "page_number": self.page_number,
            "snippet": self.snippet
        }


class RetrievedChunk:
    """Retrieved document chunk with metadata."""
    
    def __init__(
        self,
        content: str,
        file_id: str,
        file_name: str,
        page_number: int,
        chunk_index: int,
        distance: float
    ):
        self.content = content
        self.file_id = file_id
        self.file_name = file_name
        self.page_number = page_number
        self.chunk_index = chunk_index
        self.distance = distance


class ChatResponse:
    """Chat response with citations."""
    
    def __init__(
        self,
        message: str,
        citations: List[Citation],
        timestamp: str = None
    ):
        self.message = message
        self.citations = citations
        self.timestamp = timestamp or datetime.utcnow().isoformat()
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert response to dictionary."""
        return {
            "message": self.message,
            "citations": [c.to_dict() for c in self.citations],
            "timestamp": self.timestamp
        }


class RAGQueryService:
    """Service for RAG-based question answering with LangChain and GROQ."""
    
    def __init__(self):
        """Initialize RAG query service with required services."""
        self.pinecone_service = get_pinecone_service()
        self.groq_service = get_groq_service()
        self.supabase_service = get_supabase_service()
        
        # Initialize GROQ chat model for LangChain
        groq_api_key = os.getenv("GROQ_API_KEY")
        if not groq_api_key:
            raise ValueError("GROQ_API_KEY is required")
        
        self.chat_model = ChatGroq(
            api_key=groq_api_key,
            model="llama-3.3-70b-versatile",
            temperature=0.7
        )
        
        # Initialize embedding model (same as indexer)
        embedding_model = os.getenv("EMBEDDING_MODEL", "sentence-transformers/all-MiniLM-L6-v2")
        self.embeddings = HuggingFaceEmbeddings(
            model_name=embedding_model,
            model_kwargs={'device': 'cpu'},
            encode_kwargs={'normalize_embeddings': True}
        )
        
        # Define prompt template for RAG
        self.prompt_template = PromptTemplate(
            template="""You are a helpful AI assistant that answers questions based on the provided context from research documents.

Context from documents:
{context}

Question: {question}

Instructions:
- Answer the question based ONLY on the information provided in the context above
- If the context doesn't contain enough information to answer the question, say so
- Be concise and accurate
- Reference specific information from the context when possible

Answer:""",
            input_variables=["context", "question"]
        )
        
        logger.info("RAG Query Service initialized with GROQ chat model")
    
    async def query(
        self,
        question: str,
        user_id: str,
        selected_file_ids: Optional[List[str]] = None,
        top_k: int = 5
    ) -> ChatResponse:
        """
        Query user's vector store with source filtering using GROQ.
        
        This is the main end-to-end RAG pipeline that:
        1. Retrieves relevant context from user's Pinecone namespace
        2. Filters by selected source files if specified
        3. Generates AI response using GROQ
        4. Extracts and formats citations
        
        Args:
            question: User's question
            user_id: User UUID or Google sub ID (will be converted to UUID)
            selected_file_ids: Optional list of file IDs to filter sources
            top_k: Number of chunks to retrieve
            
        Returns:
            ChatResponse with answer and citations
            
        Raises:
            ValueError: If query fails
        """
        try:
            logger.info(f"RAG query for user {user_id}: {question[:100]}...")
            
            # Convert Google user ID to Supabase UUID if needed
            # This handles both UUID format and Google sub format
            resolved_user_id = await self._get_or_create_user_uuid(user_id)
            logger.debug(f"Resolved user_id {user_id} to UUID {resolved_user_id}")
            
            # Step 1: Retrieve relevant context with source filtering
            retrieved_chunks = await self.retrieve_context(
                question=question,
                user_id=resolved_user_id,
                selected_file_ids=selected_file_ids,
                top_k=top_k
            )
            
            if not retrieved_chunks:
                logger.warning(f"No relevant context found for query")
                return ChatResponse(
                    message="I couldn't find any relevant information in the selected documents to answer your question.",
                    citations=[]
                )
            
            # Step 2: Generate response with citations
            response = await self.generate_response(
                question=question,
                context=retrieved_chunks
            )
            
            logger.info(f"RAG query completed with {len(response.citations)} citations")
            return response
            
        except Exception as e:
            logger.error(f"RAG query failed: {str(e)}")
            raise ValueError(f"Query failed: {str(e)}")
    
    async def retrieve_context(
        self,
        question: str,
        user_id: str,
        selected_file_ids: Optional[List[str]] = None,
        top_k: int = 5
    ) -> List[RetrievedChunk]:
        """
        Retrieve relevant chunks from user's Pinecone namespace with filtering.
        
        Uses Pinecone query with metadata filtering for selected sources.
        
        Args:
            question: User's question
            user_id: User UUID
            selected_file_ids: Optional list of file IDs to filter by
            top_k: Number of chunks to retrieve
            
        Returns:
            List of RetrievedChunk objects with metadata
        """
        try:
            logger.info(f"Retrieving context for user {user_id}, top_k={top_k}")
            
            # Generate query embedding
            query_embedding = self.embeddings.embed_query(question)
            
            # Build metadata filter for selected files
            filter_dict = None
            if selected_file_ids:
                # Pinecone filter for file_id in selected_file_ids
                filter_dict = {"file_id": {"$in": selected_file_ids}}
                logger.info(f"Filtering by {len(selected_file_ids)} selected files")
            
            # Query Pinecone namespace
            results = self.pinecone_service.query_documents(
                user_id=user_id,
                query_embeddings=[query_embedding],
                n_results=top_k,
                filter=filter_dict
            )
            
            # Parse results into RetrievedChunk objects
            retrieved_chunks = []
            
            if results['ids'] and len(results['ids']) > 0:
                # Results are nested: results['ids'][0] contains list of IDs for first query
                for i in range(len(results['ids'][0])):
                    metadata = results['metadatas'][0][i]
                    document = results['documents'][0][i]
                    distance = results['distances'][0][i] if 'distances' in results else 0.0
                    
                    chunk = RetrievedChunk(
                        content=document,
                        file_id=metadata.get('file_id', ''),
                        file_name=metadata.get('file_name', 'Unknown'),
                        page_number=metadata.get('page_number', 0),
                        chunk_index=metadata.get('chunk_index', 0),
                        distance=distance
                    )
                    retrieved_chunks.append(chunk)
            
            logger.info(f"Retrieved {len(retrieved_chunks)} relevant chunks")
            return retrieved_chunks
            
        except Exception as e:
            logger.error(f"Context retrieval failed: {str(e)}")
            raise ValueError(f"Context retrieval failed: {str(e)}")
    
    async def generate_response(
        self,
        question: str,
        context: List[RetrievedChunk]
    ) -> ChatResponse:
        """
        Generate AI response with citations using GROQ via LangChain.
        
        Uses LangChain prompt templates and GROQ chat model to generate
        a response based on retrieved context, then extracts citations.
        
        Args:
            question: User's question
            context: List of retrieved chunks
            
        Returns:
            ChatResponse with answer and citations
        """
        try:
            logger.info(f"Generating response for question with {len(context)} context chunks")
            
            # Format context for prompt
            context_text = self._format_context(context)
            
            # Generate prompt using template
            prompt = self.prompt_template.format(
                context=context_text,
                question=question
            )
            
            # Call GROQ chat API
            messages = [
                {"role": "user", "content": prompt}
            ]
            
            groq_response = await self.groq_service.chat(
                messages=messages,
                temperature=0.7,
                max_tokens=1000
            )
            
            answer = groq_response['content']
            
            # Extract citations from context
            citations = self.format_citations(context)
            
            logger.info(f"Generated response with {len(citations)} citations")
            
            return ChatResponse(
                message=answer,
                citations=citations
            )
            
        except Exception as e:
            logger.error(f"Response generation failed: {str(e)}")
            raise ValueError(f"Response generation failed: {str(e)}")
    
    def _format_context(self, chunks: List[RetrievedChunk]) -> str:
        """
        Format retrieved chunks into context string for prompt.
        
        Args:
            chunks: List of retrieved chunks
            
        Returns:
            Formatted context string
        """
        context_parts = []
        
        for i, chunk in enumerate(chunks, 1):
            context_parts.append(
                f"[Source {i}: {chunk.file_name}, Page {chunk.page_number}]\n{chunk.content}\n"
            )
        
        return "\n".join(context_parts)
    
    def format_citations(
        self,
        retrieved_chunks: List[RetrievedChunk]
    ) -> List[Citation]:
        """
        Format citations with file_id, file_name, and page_number.
        
        Deduplicates citations by (file_id, page_number) to avoid
        showing the same page multiple times.
        
        Args:
            retrieved_chunks: List of retrieved chunks
            
        Returns:
            List of Citation objects
        """
        # Use dict to deduplicate by (file_id, page_number)
        citations_dict = {}
        
        for chunk in retrieved_chunks:
            key = (chunk.file_id, chunk.page_number)
            
            if key not in citations_dict:
                # Create snippet from first 150 characters
                snippet = chunk.content[:150] + "..." if len(chunk.content) > 150 else chunk.content
                
                citations_dict[key] = Citation(
                    file_id=chunk.file_id,
                    file_name=chunk.file_name,
                    page_number=chunk.page_number,
                    snippet=snippet
                )
        
        # Return citations sorted by file_name and page_number
        citations = list(citations_dict.values())
        citations.sort(key=lambda c: (c.file_name, c.page_number))
        
        return citations
    
    async def get_user_namespace(self, user_id: str) -> str:
        """
        Get user-specific Pinecone namespace.
        
        Args:
            user_id: User UUID
            
        Returns:
            Namespace string
        """
        return self.pinecone_service.get_user_namespace(user_id)
    
    async def _get_or_create_user_uuid(self, google_user_id: str) -> str:
        """
        Get Supabase UUID for a Google user ID, or create user if doesn't exist.
        
        This handles the case where frontend passes Google sub IDs (numeric strings)
        but backend needs Supabase UUIDs for database operations.
        
        Args:
            google_user_id: Google sub claim (e.g., "100368505623607269813")
            
        Returns:
            Supabase UUID string
            
        Raises:
            ValueError: If user lookup/creation fails
        """
        try:
            # Try to find existing user by google_sub
            user_response = self.supabase_service.client.table("users").select("id").eq("google_sub", google_user_id).execute()
            
            if user_response.data and len(user_response.data) > 0:
                uuid = user_response.data[0]["id"]
                logger.debug(f"Found Supabase UUID {uuid} for Google user {google_user_id}")
                return uuid
            
            # User not found - create minimal user record
            logger.warning(f"User with Google ID {google_user_id} not found, creating minimal record")
            user_data = {
                "google_sub": google_user_id,
                "email": f"user_{google_user_id}@temp.local",
                "name": f"User {google_user_id}"
            }
            create_response = self.supabase_service.client.table("users").insert(user_data).execute()
            
            if not create_response.data or len(create_response.data) == 0:
                raise ValueError("Failed to create user record")
            
            uuid = create_response.data[0]["id"]
            logger.info(f"Created user record with UUID {uuid} for Google user {google_user_id}")
            return uuid
            
        except Exception as e:
            logger.error(f"Failed to resolve user ID for {google_user_id}: {str(e)}")
            raise ValueError(f"Failed to resolve user ID: {str(e)}")


# Singleton instance
_rag_query_service: Optional[RAGQueryService] = None


def get_rag_query_service() -> RAGQueryService:
    """Get or create RAG query service singleton."""
    global _rag_query_service
    if _rag_query_service is None:
        _rag_query_service = RAGQueryService()
    return _rag_query_service
