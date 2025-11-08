"""
Pinecone service for vector storage with per-user namespaces.
Provides user-isolated vector storage for RAG indexing.
"""

import os
import logging
from typing import Optional, List, Dict, Any
from pinecone import Pinecone, ServerlessSpec

logger = logging.getLogger(__name__)


class PineconeService:
    """Service for managing Pinecone vector storage with per-user namespaces."""
    
    def __init__(self):
        """Initialize Pinecone client."""
        api_key = os.getenv("PINECONE_API_KEY")
        if not api_key:
            raise ValueError("PINECONE_API_KEY is required")
        
        # Initialize Pinecone client
        self.client = Pinecone(api_key=api_key)
        
        # Get or create index
        self.index_name = os.getenv("PINECONE_INDEX_NAME", "scholarmate")
        self.dimension = int(os.getenv("PINECONE_DIMENSION", "384"))  # Default for all-MiniLM-L6-v2
        
        # Create index if it doesn't exist
        self._ensure_index_exists()
        
        # Get index reference with host
        index_description = self.client.describe_index(self.index_name)
        self.index = self.client.Index(
            name=self.index_name,
            host=index_description.host
        )
        
        logger.info(f"Pinecone initialized with index: {self.index_name} (host: {index_description.host})")
    
    def _ensure_index_exists(self):
        """Create index if it doesn't exist."""
        try:
            existing_indexes = [idx.name for idx in self.client.list_indexes()]
            
            if self.index_name not in existing_indexes:
                logger.info(f"Creating Pinecone index: {self.index_name}")
                
                # Create serverless index (free tier)
                self.client.create_index(
                    name=self.index_name,
                    dimension=self.dimension,
                    metric="cosine",
                    spec=ServerlessSpec(
                        cloud=os.getenv("PINECONE_CLOUD", "aws"),
                        region=os.getenv("PINECONE_REGION", "us-east-1")
                    )
                )
                logger.info(f"Created Pinecone index: {self.index_name}")
            else:
                logger.info(f"Using existing Pinecone index: {self.index_name}")
                
        except Exception as e:
            logger.error(f"Failed to ensure index exists: {str(e)}")
            raise
    
    def get_user_namespace(self, user_id: str) -> str:
        """
        Get standardized namespace for a user.
        
        Args:
            user_id: User UUID
            
        Returns:
            Namespace in format: user_{user_id}
        """
        # Sanitize user_id to ensure valid namespace
        sanitized_id = user_id.replace("-", "_")
        return f"user_{sanitized_id}"
    
    def add_documents(
        self,
        user_id: str,
        documents: List[str],
        metadatas: List[Dict[str, Any]],
        ids: List[str],
        embeddings: List[List[float]]
    ) -> None:
        """
        Add documents to a user's namespace.
        
        Args:
            user_id: User UUID
            documents: List of document texts
            metadatas: List of metadata dicts (must include file_id, page_number, chunk_index)
            ids: List of unique document IDs
            embeddings: Pre-computed embeddings (required for Pinecone)
        """
        namespace = self.get_user_namespace(user_id)
        
        # Prepare vectors for upsert
        vectors = []
        for i, (doc_id, embedding, metadata, text) in enumerate(zip(ids, embeddings, metadatas, documents)):
            # Add text to metadata for retrieval
            metadata_with_text = {**metadata, "text": text}
            vectors.append({
                "id": doc_id,
                "values": embedding,
                "metadata": metadata_with_text
            })
        
        # Upsert in batches of 100 (Pinecone limit)
        batch_size = 100
        for i in range(0, len(vectors), batch_size):
            batch = vectors[i:i + batch_size]
            self.index.upsert(vectors=batch, namespace=namespace)
        
        logger.info(f"Added {len(documents)} documents to namespace {namespace}")
    
    def query_documents(
        self,
        user_id: str,
        query_embeddings: List[List[float]],
        n_results: int = 5,
        filter: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Query documents in a user's namespace.
        
        Args:
            user_id: User UUID
            query_embeddings: List of query embedding vectors
            n_results: Number of results to return per query
            filter: Optional metadata filter (e.g., {"file_id": "abc123"})
            
        Returns:
            Query results with documents, metadatas, distances, and ids
        """
        namespace = self.get_user_namespace(user_id)
        
        # Query for each embedding
        all_results = {
            "ids": [],
            "documents": [],
            "metadatas": [],
            "distances": []
        }
        
        for query_embedding in query_embeddings:
            results = self.index.query(
                vector=query_embedding,
                top_k=n_results,
                namespace=namespace,
                filter=filter,
                include_metadata=True
            )
            
            # Extract results
            ids = []
            documents = []
            metadatas = []
            distances = []
            
            for match in results.matches:
                ids.append(match.id)
                metadata = match.metadata
                documents.append(metadata.pop("text", ""))  # Extract text from metadata
                metadatas.append(metadata)
                distances.append(match.score)
            
            all_results["ids"].append(ids)
            all_results["documents"].append(documents)
            all_results["metadatas"].append(metadatas)
            all_results["distances"].append(distances)
        
        logger.info(f"Queried namespace {namespace}, returned {len(all_results['ids'][0])} results")
        
        return all_results
    
    def delete_documents_by_file(self, user_id: str, file_id: str) -> None:
        """
        Delete all documents associated with a specific file.
        
        Args:
            user_id: User UUID
            file_id: File ID to delete documents for
        """
        namespace = self.get_user_namespace(user_id)
        
        try:
            # Delete by metadata filter
            self.index.delete(
                filter={"file_id": file_id},
                namespace=namespace
            )
            logger.info(f"Deleted documents for file {file_id} in namespace {namespace}")
        except Exception as e:
            # Namespace might not exist yet (first time indexing) - this is OK
            if "not found" in str(e).lower() or "404" in str(e):
                logger.info(f"Namespace {namespace} doesn't exist yet, skipping delete")
            else:
                # Re-raise unexpected errors
                raise
    
    def get_namespace_stats(self, user_id: str) -> Dict[str, Any]:
        """
        Get statistics for a user's namespace.
        
        Args:
            user_id: User UUID
            
        Returns:
            Dict with namespace statistics
        """
        try:
            namespace = self.get_user_namespace(user_id)
            stats = self.index.describe_index_stats()
            
            # Get namespace-specific stats
            namespace_stats = stats.namespaces.get(namespace, {})
            vector_count = namespace_stats.vector_count if hasattr(namespace_stats, 'vector_count') else 0
            
            return {
                "namespace": namespace,
                "document_count": vector_count,
                "user_id": user_id
            }
        except Exception as e:
            logger.error(f"Error getting namespace stats for user {user_id}: {str(e)}")
            return {
                "namespace": self.get_user_namespace(user_id),
                "document_count": 0,
                "user_id": user_id,
                "error": str(e)
            }
    
    def delete_namespace(self, user_id: str) -> bool:
        """
        Delete all vectors in a user's namespace.
        
        Args:
            user_id: User UUID
            
        Returns:
            True if deleted, False if namespace didn't exist
        """
        namespace = self.get_user_namespace(user_id)
        
        try:
            self.index.delete(delete_all=True, namespace=namespace)
            logger.info(f"Deleted namespace: {namespace}")
            return True
        except Exception as e:
            # Namespace not existing is OK - treat as successful deletion
            if "not found" in str(e).lower() or "404" in str(e):
                logger.info(f"Namespace {namespace} doesn't exist, nothing to delete")
                return True
            logger.warning(f"Failed to delete namespace {namespace}: {str(e)}")
            return False


# Singleton instance
_pinecone_service: Optional[PineconeService] = None


def get_pinecone_service() -> PineconeService:
    """Get or create Pinecone service singleton."""
    global _pinecone_service
    if _pinecone_service is None:
        _pinecone_service = PineconeService()
    return _pinecone_service
