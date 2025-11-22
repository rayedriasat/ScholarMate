"""
Advanced Search Service for ScholarMate.
Provides multi-dimensional search across file names, content, and metadata.
"""

import logging
from typing import List, Dict, Any, Optional
from datetime import datetime
import re

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
        match_type: str,  # 'exact', 'partial', 'semantic', 'fuzzy'
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


class SearchService:
    """Service for advanced multi-dimensional search."""
    
    def __init__(self):
        """Initialize search service."""
        self.pinecone_service = get_pinecone_service()
        self.supabase_service = get_supabase_service()
        self.embedding_service = get_embedding_service(strategy=EmbeddingStrategy.AUTO)
        logger.info("Search Service initialized")
    
    async def search(
        self,
        query: str,
        user_id: str,
        max_results: int = 20,
        include_semantic: bool = True
    ) -> List[SearchResult]:
        """
        Perform multi-dimensional search across file names and content.
        
        Search strategy:
        1. Exact matches in file names (highest priority)
        2. Partial/fuzzy matches in file names
        3. Semantic search in document content (if enabled)
        4. Combine and rank results by relevance
        
        Args:
            query: Search query (word, phrase, or sentence)
            user_id: User UUID or Google sub ID
            max_results: Maximum number of results to return
            include_semantic: Whether to include semantic search
            
        Returns:
            List of SearchResult objects, ranked by relevance
        """
        try:
            logger.info(f"Search query for user {user_id}: '{query}' (semantic: {include_semantic})")
            
            if not query.strip():
                return []
            
            # Convert Google user ID to Supabase UUID if needed
            resolved_user_id = await self._get_or_create_user_uuid(user_id)
            logger.debug(f"Resolved user_id {user_id} to UUID {resolved_user_id}")
            
            # Normalize query
            normalized_query = query.strip().lower()
            
            # Get user's files from Supabase
            files_response = self.supabase_service.client.table("files").select(
                "id, name, mime_type, size_bytes, drive_modified_time"
            ).eq("user_id", resolved_user_id).execute()
            
            user_files = files_response.data if files_response.data else []
            logger.info(f"Found {len(user_files)} files for user")
            
            # Log sample filenames for debugging
            if user_files:
                sample_names = [f.get('name', 'unnamed')[:50] for f in user_files[:5]]
                logger.debug(f"Sample filenames: {sample_names}")
            
            all_results = []
            
            # 1. Search file names (exact and partial matches)
            filename_results = self._search_filenames(normalized_query, user_files)
            all_results.extend(filename_results)
            
            # 2. Semantic search in content (if enabled)
            if include_semantic:
                semantic_results = await self._semantic_search(query, resolved_user_id, max_results)
                all_results.extend(semantic_results)
            
            # 3. Deduplicate and rank results
            ranked_results = self._rank_and_deduplicate(all_results, max_results)
            
            logger.info(f"Search completed: {len(ranked_results)} results (filename: {len(filename_results)}, semantic: {len(semantic_results) if include_semantic else 0})")
            
            # Log top results for debugging
            if ranked_results:
                for i, r in enumerate(ranked_results[:3], 1):
                    logger.debug(f"Result {i}: {r.file_name} ({r.match_type}, {r.relevance_score:.2f})")
            
            return ranked_results
            
        except Exception as e:
            logger.error(f"Search failed: {str(e)}")
            raise ValueError(f"Search failed: {str(e)}")
    
    def _search_filenames(
        self,
        query: str,
        files: List[Dict[str, Any]]
    ) -> List[SearchResult]:
        """
        Search file names for exact and partial matches with improved scoring.
        
        Args:
            query: Normalized search query
            files: List of file metadata dicts
            
        Returns:
            List of SearchResult objects
        """
        results = []
        query_words = query.split()
        
        for file in files:
            file_name = file.get("name", "").lower()
            file_id = file.get("id", "")
            
            # Skip if no name or is a folder
            if not file_name or file.get("is_folder", False):
                continue
            
            # Remove file extension for better matching
            file_name_no_ext = file_name.rsplit('.', 1)[0] if '.' in file_name else file_name
            
            # 1. EXACT MATCH - Full filename (case-insensitive)
            original_name = file.get("name", "")
            if query == file_name or query == file_name_no_ext:
                results.append(SearchResult(
                    file_id=file_id,
                    file_name=original_name,
                    match_type="exact",
                    relevance_score=1.0,
                    snippet=f"Exact filename match",
                    match_context="filename",
                    file_size=file.get("size_bytes"),
                    modified_time=file.get("drive_modified_time"),
                    mime_type=file.get("mime_type")
                ))
                continue
            
            # 2. STARTS WITH - Query at beginning of filename
            if file_name.startswith(query) or file_name_no_ext.startswith(query):
                length_ratio = len(query) / len(file_name_no_ext)
                relevance = 0.85 + (0.1 * length_ratio)
                
                results.append(SearchResult(
                    file_id=file_id,
                    file_name=file.get("name", ""),
                    match_type="partial",
                    relevance_score=min(relevance, 0.95),
                    snippet=f"Starts with: {file.get('name', '')}",
                    match_context="filename",
                    file_size=file.get("size_bytes"),
                    modified_time=file.get("drive_modified_time"),
                    mime_type=file.get("mime_type")
                ))
                continue
            
            # 3. CONTAINS - Query anywhere in filename
            if query in file_name:
                position = file_name.index(query)
                length_ratio = len(query) / len(file_name)
                position_score = 1.0 - (position / len(file_name))
                
                # Bonus for word boundary matches
                is_word_boundary = (position == 0 or file_name[position - 1] in ' -_.')
                boundary_bonus = 0.1 if is_word_boundary else 0
                
                relevance = 0.65 + (0.15 * length_ratio) + (0.1 * position_score) + boundary_bonus
                
                results.append(SearchResult(
                    file_id=file_id,
                    file_name=file.get("name", ""),
                    match_type="partial",
                    relevance_score=min(relevance, 0.9),
                    snippet=f"Contains: {file.get('name', '')}",
                    match_context="filename",
                    file_size=file.get("size_bytes"),
                    modified_time=file.get("drive_modified_time"),
                    mime_type=file.get("mime_type")
                ))
                continue
            
            # 4. WORD MATCH - All query words present (for multi-word queries)
            if len(query_words) > 1:
                file_words = re.split(r'[\s\-_\.]+', file_name_no_ext)
                
                # Check if all query words are in filename
                all_words_match = all(
                    any(query_word in file_word for file_word in file_words)
                    for query_word in query_words
                )
                
                if all_words_match:
                    # Calculate match quality
                    exact_word_matches = sum(
                        1 for query_word in query_words
                        if query_word in file_words
                    )
                    match_ratio = exact_word_matches / len(query_words)
                    relevance = 0.55 + (0.25 * match_ratio)
                    
                    results.append(SearchResult(
                        file_id=file_id,
                        file_name=file.get("name", ""),
                        match_type="fuzzy",
                        relevance_score=min(relevance, 0.8),
                        snippet=f"All words match: {file.get('name', '')}",
                        match_context="filename",
                        file_size=file.get("size_bytes"),
                        modified_time=file.get("drive_modified_time"),
                        mime_type=file.get("mime_type")
                    ))
                    continue
                
                # Check if some query words are in filename
                matching_words = sum(
                    1 for query_word in query_words
                    if any(query_word in file_word for file_word in file_words)
                )
                
                if matching_words > 0:
                    match_ratio = matching_words / len(query_words)
                    # Only include if at least 50% of words match
                    if match_ratio >= 0.5:
                        relevance = 0.35 + (0.35 * match_ratio)
                        
                        results.append(SearchResult(
                            file_id=file_id,
                            file_name=file.get("name", ""),
                            match_type="fuzzy",
                            relevance_score=min(relevance, 0.7),
                            snippet=f"Partial words match: {file.get('name', '')}",
                            match_context="filename",
                            file_size=file.get("size_bytes"),
                            modified_time=file.get("drive_modified_time"),
                            mime_type=file.get("mime_type")
                        ))
            
            # 5. SINGLE WORD PARTIAL - For single word queries, check word boundaries
            elif len(query_words) == 1:
                file_words = re.split(r'[\s\-_\.]+', file_name_no_ext)
                
                # Check if query is part of any word
                for file_word in file_words:
                    if query in file_word and query != file_word:
                        # Calculate how much of the word matches
                        match_ratio = len(query) / len(file_word)
                        relevance = 0.4 + (0.3 * match_ratio)
                        
                        results.append(SearchResult(
                            file_id=file_id,
                            file_name=file.get("name", ""),
                            match_type="fuzzy",
                            relevance_score=min(relevance, 0.7),
                            snippet=f"Word contains: {file.get('name', '')}",
                            match_context="filename",
                            file_size=file.get("size_bytes"),
                            modified_time=file.get("drive_modified_time"),
                            mime_type=file.get("mime_type")
                        ))
                        break
        
        return results
    
    async def _semantic_search(
        self,
        query: str,
        user_id: str,
        max_results: int
    ) -> List[SearchResult]:
        """
        Perform semantic search in document content using Pinecone with improved scoring.
        
        Args:
            query: Search query
            user_id: User UUID
            max_results: Maximum results to retrieve
            
        Returns:
            List of SearchResult objects
        """
        try:
            # Generate query embedding
            query_embedding = await self.embedding_service.generate_query_embedding(query)
            
            # Query Pinecone with more results to allow for better filtering
            results = self.pinecone_service.query_documents(
                user_id=user_id,
                query_embeddings=[query_embedding],
                n_results=max_results * 2,  # Get more results for better quality
                filter=None
            )
            
            semantic_results = []
            query_lower = query.lower()
            
            if results['ids'] and len(results['ids']) > 0:
                for i in range(len(results['ids'][0])):
                    metadata = results['metadatas'][0][i]
                    document = results['documents'][0][i]
                    distance = results['distances'][0][i] if 'distances' in results else 0.0
                    
                    # Convert distance to similarity score (0-1)
                    # Pinecone cosine distance: 0 = identical, 2 = opposite
                    similarity = max(0, 1 - (distance / 2))
                    
                    content_lower = document.lower()
                    query_words = query_lower.split()
                    
                    # CRITICAL: Only include if query words actually appear in content
                    # This prevents false positives from semantic similarity alone
                    word_matches = sum(1 for word in query_words if len(word) > 2 and word in content_lower)
                    
                    # Require at least 50% of meaningful words (>2 chars) to be present
                    meaningful_words = [w for w in query_words if len(w) > 2]
                    if meaningful_words:
                        required_matches = max(1, len(meaningful_words) // 2)
                        if word_matches < required_matches:
                            continue
                    
                    # Only include results with good similarity (>0.4)
                    if similarity < 0.4:
                        continue
                    
                    word_match_bonus = (word_matches / len(query_words)) * 0.15 if query_words else 0
                    
                    # Scale semantic matches to 0.25-0.85 range
                    # Higher similarity gets higher scores
                    base_relevance = 0.25 + (similarity * 0.6)
                    relevance = min(base_relevance + word_match_bonus, 0.85)
                    
                    # Create better snippet - try to find query context
                    snippet = self._extract_snippet(document, query_lower, max_length=250)
                    
                    semantic_results.append(SearchResult(
                        file_id=metadata.get('file_id', ''),
                        file_name=metadata.get('file_name', 'Unknown'),
                        match_type="semantic",
                        relevance_score=relevance,
                        snippet=snippet,
                        page_number=metadata.get('page_number'),
                        match_context="content"
                    ))
            
            # Sort by relevance and limit
            semantic_results.sort(key=lambda r: r.relevance_score, reverse=True)
            return semantic_results[:max_results]
            
        except Exception as e:
            logger.error(f"Semantic search failed: {str(e)}")
            # Return empty list on failure (don't break entire search)
            return []
    
    def _extract_snippet(self, text: str, query: str, max_length: int = 250) -> str:
        """
        Extract a relevant snippet from text that includes query terms.
        
        Args:
            text: Full text content
            query: Search query (lowercase)
            max_length: Maximum snippet length
            
        Returns:
            Relevant snippet with ellipsis if truncated
        """
        text_lower = text.lower()
        query_words = query.split()
        
        # Try to find first occurrence of any query word
        best_position = -1
        for word in query_words:
            pos = text_lower.find(word)
            if pos != -1 and (best_position == -1 or pos < best_position):
                best_position = pos
        
        if best_position == -1:
            # No query words found, return beginning
            snippet = text[:max_length]
            return snippet + "..." if len(text) > max_length else snippet
        
        # Extract context around the match
        context_start = max(0, best_position - 50)
        context_end = min(len(text), best_position + max_length - 50)
        
        snippet = text[context_start:context_end]
        
        # Add ellipsis if truncated
        if context_start > 0:
            snippet = "..." + snippet
        if context_end < len(text):
            snippet = snippet + "..."
        
        return snippet.strip()
    
    def _rank_and_deduplicate(
        self,
        results: List[SearchResult],
        max_results: int
    ) -> List[SearchResult]:
        """
        Rank and deduplicate search results.
        
        For files with multiple matches (e.g., filename + content),
        keep the highest-scoring match.
        
        Args:
            results: List of all search results
            max_results: Maximum results to return
            
        Returns:
            Ranked and deduplicated list of SearchResult objects
        """
        # Group by file_id and keep highest score
        file_results = {}
        
        for result in results:
            file_id = result.file_id
            
            if file_id not in file_results:
                file_results[file_id] = result
            else:
                # Keep result with higher relevance score
                if result.relevance_score > file_results[file_id].relevance_score:
                    file_results[file_id] = result
        
        # Sort by relevance score (descending)
        ranked = sorted(
            file_results.values(),
            key=lambda r: r.relevance_score,
            reverse=True
        )
        
        # Limit to max_results
        return ranked[:max_results]
    
    async def _get_or_create_user_uuid(self, google_user_id: str) -> str:
        """
        Get Supabase UUID for a Google user ID, or create user if doesn't exist.
        
        This handles the case where frontend passes Google sub IDs (numeric strings)
        but backend needs Supabase UUIDs for database operations.
        
        Args:
            google_user_id: Google sub claim (e.g., "103136320510419145687")
            
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
_search_service: Optional[SearchService] = None


def get_search_service() -> SearchService:
    """Get or create search service singleton."""
    global _search_service
    if _search_service is None:
        _search_service = SearchService()
    return _search_service
