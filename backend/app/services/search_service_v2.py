"""
Simple and Accurate Search Service for ScholarMate.
Focus: Precision over complexity.
"""

import logging
from typing import List, Dict, Any, Optional

from .pinecone_service import get_pinecone_service
from .supabase_service import get_supabase_service
from .embedding_service import get_embedding_service, EmbeddingStrategy

logger = logging.getLogger(__name__)


class SearchResult:
    """Search result with relevance scoring."""
    
    def __init__(
        self,
        file_id: str,
        file_name: str,
        match_type: str,
        relevance_score: float,
        snippet: str = "",
        page_number: Optional[int] = None,
        match_context: Optional[str] = None,
        file_size: Optional[int] = None,
        modified_time: Optional[str] = None,
        mime_type: Optional[str] = None
    ):
        self.file_id = file_id
        self.file_name = file_name
        self.match_type = match_type
        self.relevance_score = relevance_score
        self.snippet = snippet
        self.page_number = page_number
        self.match_context = match_context
        self.file_size = file_size
        self.modified_time = modified_time
        self.mime_type = mime_type
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            "file_id": self.file_id,
            "file_name": self.file_name,
            "match_type": self.match_type,
            "relevance_score": self.relevance_score,
            "snippet": self.snippet,
            "page_number": self.page_number,
            "match_context": self.match_context,
            "file_size": self.file_size,
            "modified_time": self.modified_time,
            "mime_type": self.mime_type
        }


class SimpleSearchService:
    """Simple, accurate search service."""
    
    def __init__(self):
        """Initialize search service."""
        self.pinecone_service = get_pinecone_service()
        self.supabase_service = get_supabase_service()
        self.embedding_service = get_embedding_service(strategy=EmbeddingStrategy.AUTO)
        logger.info("Simple Search Service initialized")
    
    async def search(
        self,
        query: str,
        user_id: str,
        max_results: int = 20,
        include_semantic: bool = True
    ) -> List[SearchResult]:
        """
        Simple, accurate search.
        
        Strategy:
        1. Search filenames (simple substring match)
        2. If semantic enabled, search content (strict word matching)
        3. Combine and sort by relevance
        """
        try:
            logger.info(f"Search: '{query}' for user {user_id} (semantic: {include_semantic})")
            
            if not query.strip():
                return []
            
            # Convert Google ID to UUID
            resolved_user_id = await self._get_user_uuid(user_id)
            
            # Normalize query
            query_lower = query.strip().lower()
            
            # Get user's files
            files_response = self.supabase_service.client.table("files").select(
                "id, name, mime_type, size_bytes, drive_modified_time, is_folder"
            ).eq("user_id", resolved_user_id).execute()
            
            files = files_response.data if files_response.data else []
            logger.info(f"Searching {len(files)} files")
            
            results = []
            
            # 1. Filename search
            for file in files:
                # Skip folders
                if file.get("is_folder", False):
                    continue
                
                filename = file.get("name", "")
                filename_lower = filename.lower()
                
                # Simple substring match
                if query_lower in filename_lower:
                    # Calculate score based on match quality
                    if query_lower == filename_lower:
                        score = 1.0
                        match_type = "exact"
                    elif filename_lower.startswith(query_lower):
                        score = 0.9
                        match_type = "partial"
                    else:
                        score = 0.7
                        match_type = "partial"
                    
                    results.append(SearchResult(
                        file_id=file["id"],
                        file_name=filename,
                        match_type=match_type,
                        relevance_score=score,
                        snippet=f"Filename contains: '{query}'",
                        match_context="filename",
                        file_size=file.get("size_bytes"),
                        modified_time=file.get("drive_modified_time"),
                        mime_type=file.get("mime_type")
                    ))
            
            logger.info(f"Filename search: {len(results)} results")
            
            # 2. Content search (if enabled)
            if include_semantic:
                try:
                    content_results = await self._search_content(query, resolved_user_id, max_results)
                    results.extend(content_results)
                    logger.info(f"Content search: {len(content_results)} results")
                except Exception as e:
                    logger.error(f"Content search failed: {e}")
            
            # 3. Deduplicate and sort
            unique_results = {}
            for result in results:
                file_id = result.file_id
                if file_id not in unique_results or result.relevance_score > unique_results[file_id].relevance_score:
                    unique_results[file_id] = result
            
            final_results = sorted(
                unique_results.values(),
                key=lambda r: r.relevance_score,
                reverse=True
            )[:max_results]
            
            logger.info(f"Final: {len(final_results)} results")
            return final_results
            
        except Exception as e:
            logger.error(f"Search failed: {e}", exc_info=True)
            raise ValueError(f"Search failed: {str(e)}")
    
    async def _search_content(
        self,
        query: str,
        user_id: str,
        max_results: int
    ) -> List[SearchResult]:
        """
        Search document content - STRICT matching only.
        Only returns results where query words actually appear.
        """
        try:
            query_lower = query.lower()
            query_words = [w for w in query_lower.split() if len(w) > 2]
            
            if not query_words:
                return []
            
            # Generate embedding
            query_embedding = await self.embedding_service.generate_query_embedding(query)
            
            # Query Pinecone
            results = self.pinecone_service.query_documents(
                user_id=user_id,
                query_embeddings=[query_embedding],
                n_results=max_results * 3,
                filter=None
            )
            
            content_results = []
            
            if results['ids'] and len(results['ids']) > 0:
                for i in range(len(results['ids'][0])):
                    metadata = results['metadatas'][0][i]
                    document = results['documents'][0][i]
                    distance = results['distances'][0][i] if 'distances' in results else 0.0
                    
                    content_lower = document.lower()
                    
                    # STRICT: Check if ALL query words appear in content
                    words_found = sum(1 for word in query_words if word in content_lower)
                    
                    # Require ALL words to be present
                    if words_found < len(query_words):
                        continue
                    
                    # Calculate similarity
                    similarity = max(0, 1 - (distance / 2))
                    
                    # Only include high-quality matches
                    if similarity < 0.5:
                        continue
                    
                    # Score: 0.5-0.85 range (below filename matches)
                    score = 0.5 + (similarity * 0.35)
                    
                    # Extract snippet around query
                    snippet = self._extract_snippet(document, query_lower)
                    
                    content_results.append(SearchResult(
                        file_id=metadata.get('file_id', ''),
                        file_name=metadata.get('file_name', 'Unknown'),
                        match_type="semantic",
                        relevance_score=score,
                        snippet=snippet,
                        page_number=metadata.get('page_number'),
                        match_context="content"
                    ))
            
            # Sort by score and limit
            content_results.sort(key=lambda r: r.relevance_score, reverse=True)
            return content_results[:max_results]
            
        except Exception as e:
            logger.error(f"Content search error: {e}")
            return []
    
    def _extract_snippet(self, text: str, query: str, max_len: int = 200) -> str:
        """Extract snippet around query match."""
        text_lower = text.lower()
        
        # Find first query word
        pos = text_lower.find(query.split()[0])
        if pos == -1:
            return text[:max_len] + ("..." if len(text) > max_len else "")
        
        # Extract context
        start = max(0, pos - 50)
        end = min(len(text), pos + max_len - 50)
        
        snippet = text[start:end]
        if start > 0:
            snippet = "..." + snippet
        if end < len(text):
            snippet = snippet + "..."
        
        return snippet.strip()
    
    async def _get_user_uuid(self, google_user_id: str) -> str:
        """Convert Google ID to Supabase UUID."""
        try:
            response = self.supabase_service.client.table("users").select("id").eq("google_sub", google_user_id).execute()
            
            if response.data and len(response.data) > 0:
                return response.data[0]["id"]
            
            # Create user if not exists
            logger.warning(f"Creating user for Google ID: {google_user_id}")
            user_data = {
                "google_sub": google_user_id,
                "email": f"user_{google_user_id}@temp.local",
                "name": f"User {google_user_id}"
            }
            create_response = self.supabase_service.client.table("users").insert(user_data).execute()
            
            if create_response.data and len(create_response.data) > 0:
                return create_response.data[0]["id"]
            
            raise ValueError("Failed to create user")
            
        except Exception as e:
            logger.error(f"User UUID resolution failed: {e}")
            raise ValueError(f"User resolution failed: {str(e)}")


# Singleton
_simple_search_service: Optional[SimpleSearchService] = None


def get_simple_search_service() -> SimpleSearchService:
    """Get search service singleton."""
    global _simple_search_service
    if _simple_search_service is None:
        _simple_search_service = SimpleSearchService()
    return _simple_search_service
