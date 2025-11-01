"""
ChromaDB service for vector storage with per-user collections.
Provides user-isolated vector storage for RAG indexing.
"""

import os
import logging
from typing import Optional, List, Dict, Any
import chromadb
from chromadb.config import Settings
from chromadb.api.models.Collection import Collection

logger = logging.getLogger(__name__)


class ChromaService:
    """Service for managing ChromaDB vector storage with per-user collections."""
    
    def __init__(self):
        """Initialize ChromaDB client with persistent storage."""
        persist_dir = os.getenv("CHROMA_PERSIST_DIR", "./chroma_db")
        
        # Create persist directory if it doesn't exist
        os.makedirs(persist_dir, exist_ok=True)
        
        # Initialize ChromaDB client with persistent storage
        self.client = chromadb.PersistentClient(
            path=persist_dir,
            settings=Settings(
                anonymized_telemetry=False,
                allow_reset=True
            )
        )
        
        logger.info(f"ChromaDB initialized with persist directory: {persist_dir}")
    
    def get_user_collection_name(self, user_id: str) -> str:
        """
        Get standardized collection name for a user.
        
        Args:
            user_id: User UUID
            
        Returns:
            Collection name in format: user_{user_id}_documents
        """
        # Sanitize user_id to ensure valid collection name
        # ChromaDB collection names must be 3-63 characters, alphanumeric + underscores/hyphens
        sanitized_id = user_id.replace("-", "_")
        return f"user_{sanitized_id}_documents"
    
    def get_or_create_user_collection(
        self,
        user_id: str,
        embedding_function: Optional[Any] = None
    ) -> Collection:
        """
        Get or create a collection for a specific user.
        
        Args:
            user_id: User UUID
            embedding_function: Optional embedding function (defaults to ChromaDB's default)
            
        Returns:
            ChromaDB Collection object
        """
        collection_name = self.get_user_collection_name(user_id)
        
        try:
            # Try to get existing collection
            collection = self.client.get_collection(
                name=collection_name,
                embedding_function=embedding_function
            )
            logger.info(f"Retrieved existing collection: {collection_name}")
            
        except Exception:
            # Collection doesn't exist, create it
            collection = self.client.create_collection(
                name=collection_name,
                embedding_function=embedding_function,
                metadata={"user_id": user_id}
            )
            logger.info(f"Created new collection: {collection_name}")
        
        return collection
    
    def delete_user_collection(self, user_id: str) -> bool:
        """
        Delete a user's collection.
        
        Args:
            user_id: User UUID
            
        Returns:
            True if deleted, False if collection didn't exist
        """
        collection_name = self.get_user_collection_name(user_id)
        
        try:
            self.client.delete_collection(name=collection_name)
            logger.info(f"Deleted collection: {collection_name}")
            return True
        except Exception as e:
            logger.warning(f"Failed to delete collection {collection_name}: {str(e)}")
            return False
    
    def list_user_collections(self) -> List[str]:
        """
        List all user collections.
        
        Returns:
            List of collection names
        """
        collections = self.client.list_collections()
        return [col.name for col in collections]
    
    def get_collection_stats(self, user_id: str) -> Dict[str, Any]:
        """
        Get statistics for a user's collection.
        
        Args:
            user_id: User UUID
            
        Returns:
            Dict with collection statistics
        """
        try:
            collection = self.get_or_create_user_collection(user_id)
            count = collection.count()
            
            return {
                "collection_name": self.get_user_collection_name(user_id),
                "document_count": count,
                "user_id": user_id
            }
        except Exception as e:
            logger.error(f"Error getting collection stats for user {user_id}: {str(e)}")
            return {
                "collection_name": self.get_user_collection_name(user_id),
                "document_count": 0,
                "user_id": user_id,
                "error": str(e)
            }
    
    def add_documents(
        self,
        user_id: str,
        documents: List[str],
        metadatas: List[Dict[str, Any]],
        ids: List[str],
        embeddings: Optional[List[List[float]]] = None
    ) -> None:
        """
        Add documents to a user's collection.
        
        Args:
            user_id: User UUID
            documents: List of document texts
            metadatas: List of metadata dicts (must include file_id, page_number, chunk_index)
            ids: List of unique document IDs
            embeddings: Optional pre-computed embeddings
        """
        collection = self.get_or_create_user_collection(user_id)
        
        if embeddings:
            collection.add(
                documents=documents,
                metadatas=metadatas,
                ids=ids,
                embeddings=embeddings
            )
        else:
            collection.add(
                documents=documents,
                metadatas=metadatas,
                ids=ids
            )
        
        logger.info(f"Added {len(documents)} documents to collection for user {user_id}")
    
    def query_documents(
        self,
        user_id: str,
        query_texts: List[str],
        n_results: int = 5,
        where: Optional[Dict[str, Any]] = None,
        where_document: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Query documents in a user's collection.
        
        Args:
            user_id: User UUID
            query_texts: List of query strings
            n_results: Number of results to return per query
            where: Optional metadata filter (e.g., {"file_id": "abc123"})
            where_document: Optional document content filter
            
        Returns:
            Query results with documents, metadatas, distances, and ids
        """
        # Get collection with default embedding function
        from chromadb.utils import embedding_functions
        default_ef = embedding_functions.DefaultEmbeddingFunction()
        
        collection = self.get_or_create_user_collection(user_id, embedding_function=default_ef)
        
        results = collection.query(
            query_texts=query_texts,
            n_results=n_results,
            where=where,
            where_document=where_document
        )
        
        logger.info(f"Queried collection for user {user_id}, returned {len(results['ids'][0])} results")
        
        return results
    
    def delete_documents_by_file(self, user_id: str, file_id: str) -> None:
        """
        Delete all documents associated with a specific file.
        
        Args:
            user_id: User UUID
            file_id: File ID to delete documents for
        """
        collection = self.get_or_create_user_collection(user_id)
        
        # Query for all documents with this file_id
        results = collection.get(
            where={"file_id": file_id}
        )
        
        if results['ids']:
            collection.delete(ids=results['ids'])
            logger.info(f"Deleted {len(results['ids'])} documents for file {file_id}")
        else:
            logger.info(f"No documents found for file {file_id}")
    
    def reset_database(self) -> None:
        """
        Reset the entire ChromaDB database (USE WITH CAUTION).
        This will delete all collections and data.
        """
        logger.warning("Resetting ChromaDB database - all data will be lost!")
        self.client.reset()
        logger.info("ChromaDB database reset complete")


# Singleton instance
_chroma_service: Optional[ChromaService] = None


def get_chroma_service() -> ChromaService:
    """Get or create ChromaDB service singleton."""
    global _chroma_service
    if _chroma_service is None:
        _chroma_service = ChromaService()
    return _chroma_service
