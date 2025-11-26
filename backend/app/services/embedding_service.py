"""
Hybrid Embedding Service.
Supports multiple embedding strategies:
1. HuggingFace Inference API (for web, queries, and fallback)
2. Local model (for backend processing when API unavailable)
3. On-device (future: for Android via Flutter)
"""

import os
import logging
import asyncio
import gc
from typing import List, Optional
from enum import Enum

import requests
from langchain_huggingface import HuggingFaceEmbeddings

logger = logging.getLogger(__name__)


class EmbeddingStrategy(str, Enum):
    """Embedding generation strategies."""
    API = "api"  # HuggingFace Inference API
    LOCAL = "local"  # Local model on backend
    AUTO = "auto"  # Automatic selection based on availability


class EmbeddingService:
    """
    Hybrid embedding service with multiple strategies.
    
    Priority:
    1. HuggingFace Inference API (free tier, fast, no RAM)
    2. Local model (fallback, uses backend RAM)
    """
    
    def __init__(self, strategy: EmbeddingStrategy = EmbeddingStrategy.AUTO):
        """
        Initialize embedding service.
        
        Args:
            strategy: Embedding generation strategy
        """
        self.strategy = strategy
        
        # HuggingFace API configuration
        self.hf_token = os.getenv("HUGGINGFACEHUB_API_TOKEN")
        self.model_name = "sentence-transformers/all-MiniLM-L6-v2"
        # Use models endpoint (works with both old and new infrastructure)
        self.api_url = f"https://router.huggingface.co/models/{self.model_name}"
        
        # Local model configuration (lazy-loaded)
        self._local_embeddings = None
        self._local_model_path = os.path.join(
            os.path.dirname(__file__), "..", "..", "models", "all-MiniLM-L6-v2"
        )
        
        # API availability tracking
        self._api_available = None
        self._api_check_time = 0
        self.API_CHECK_INTERVAL = 300  # Check API availability every 5 minutes
        
        logger.info(f"Embedding service initialized with strategy: {strategy}")
    
    async def generate_embeddings(
        self,
        texts: List[str],
        strategy: Optional[EmbeddingStrategy] = None
    ) -> List[List[float]]:
        """
        Generate embeddings using specified or auto-selected strategy.
        
        Args:
            texts: List of text strings to embed
            strategy: Optional override for embedding strategy
            
        Returns:
            List of embedding vectors
            
        Raises:
            ValueError: If embedding generation fails with all strategies
        """
        strategy = strategy or self.strategy
        
        if strategy == EmbeddingStrategy.AUTO:
            # Use local model directly (API endpoint deprecated)
            # This ensures consistent embeddings across all operations
            logger.info("Using local model for consistent embeddings")
            return await self._generate_with_local(texts)
        
        elif strategy == EmbeddingStrategy.API:
            return await self._generate_with_api(texts)
        
        elif strategy == EmbeddingStrategy.LOCAL:
            return await self._generate_with_local(texts)
        
        else:
            raise ValueError(f"Unknown embedding strategy: {strategy}")
    
    async def _generate_with_api(self, texts: List[str]) -> List[List[float]]:
        """
        Generate embeddings using HuggingFace Inference API.
        
        Free tier: 1000 requests/day
        Rate limit: ~30 requests/minute
        
        Args:
            texts: List of text strings
            
        Returns:
            List of embedding vectors
            
        Raises:
            ValueError: If API call fails
        """
        if not self.hf_token:
            raise ValueError("HUGGINGFACEHUB_API_TOKEN not configured")
        
        try:
            logger.info(f"Generating {len(texts)} embeddings via HuggingFace API")
            
            headers = {
                "Authorization": f"Bearer {self.hf_token}",
                "Content-Type": "application/json"
            }
            
            # API accepts batch requests
            payload = {
                "inputs": texts,
                "options": {
                    "wait_for_model": True,  # Wait if model is loading
                    "use_cache": True
                }
            }
            
            # Make API request (synchronous, but fast)
            response = requests.post(
                self.api_url,
                headers=headers,
                json=payload,
                timeout=30
            )
            
            if response.status_code == 503:
                # Model is loading, retry after delay
                logger.info("Model loading, retrying in 5 seconds...")
                await asyncio.sleep(5)
                response = requests.post(
                    self.api_url,
                    headers=headers,
                    json=payload,
                    timeout=30
                )
            
            if response.status_code == 429:
                raise ValueError("Rate limit exceeded. Try again later or use local model.")
            
            if response.status_code != 200:
                raise ValueError(f"API error {response.status_code}: {response.text}")
            
            embeddings = response.json()
            
            # API returns nested list for single input, flat list for batch
            if isinstance(embeddings[0], list) and isinstance(embeddings[0][0], list):
                # Nested format: [[embedding1], [embedding2], ...]
                embeddings = [emb[0] if isinstance(emb[0], list) else emb for emb in embeddings]
            
            logger.info(f"Generated {len(embeddings)} embeddings via API")
            self._api_available = True
            
            return embeddings
            
        except Exception as e:
            logger.error(f"API embedding generation failed: {str(e)}")
            self._api_available = False
            raise ValueError(f"API embedding failed: {str(e)}")
    
    async def _generate_with_local(
        self,
        texts: List[str],
        batch_size: int = 3
    ) -> List[List[float]]:
        """
        Generate embeddings using local HuggingFace model.
        
        Memory-optimized: processes in small batches with cleanup.
        
        Args:
            texts: List of text strings
            batch_size: Batch size for processing
            
        Returns:
            List of embedding vectors
        """
        try:
            logger.info(f"Generating {len(texts)} embeddings with local model")
            
            # Lazy-load local model
            if self._local_embeddings is None:
                await self._load_local_model()
            
            # Process in small batches to minimize memory
            all_embeddings = []
            
            for i in range(0, len(texts), batch_size):
                batch_texts = texts[i:i+batch_size]
                
                # Generate embeddings for batch
                batch_embeddings = self._local_embeddings.embed_documents(batch_texts)
                all_embeddings.extend(batch_embeddings)
                
                # Cleanup
                del batch_texts
                del batch_embeddings
                gc.collect()
                
                await asyncio.sleep(0.1)
                
                logger.debug(f"Processed batch {i//batch_size + 1}/{(len(texts) + batch_size - 1)//batch_size}")
            
            logger.info(f"Generated {len(all_embeddings)} embeddings with local model")
            return all_embeddings
            
        except Exception as e:
            logger.error(f"Local embedding generation failed: {str(e)}")
            raise ValueError(f"Local embedding failed: {str(e)}")
    
    async def _load_local_model(self):
        """Lazy-load local embedding model."""
        logger.info("Loading local embedding model...")
        
        try:
            # Check for local model first
            if os.path.exists(self._local_model_path):
                model_name = self._local_model_path
                logger.info(f"Using local model from: {model_name}")
            else:
                model_name = self.model_name
                logger.info(f"Downloading model: {model_name}")
            
            # Authenticate with HuggingFace if token available
            if self.hf_token:
                try:
                    from huggingface_hub import login
                    login(token=self.hf_token)
                    logger.info("Authenticated with HuggingFace Hub")
                except Exception as e:
                    logger.warning(f"HF authentication failed: {e}")
            
            # Initialize embeddings
            self._local_embeddings = HuggingFaceEmbeddings(
                model_name=model_name,
                model_kwargs={'device': 'cpu'},
                encode_kwargs={'normalize_embeddings': True}
            )
            
            logger.info("Local embedding model loaded successfully")
            
        except Exception as e:
            logger.error(f"Failed to load local model: {str(e)}")
            raise
    
    async def generate_query_embedding(self, query: str) -> List[float]:
        """
        Generate embedding for a single query.
        
        Uses local model for consistency with indexed documents.
        
        Args:
            query: Query text
            
        Returns:
            Embedding vector
        """
        # Use local model for consistency
        if self._local_embeddings is None:
            await self._load_local_model()
        
        return self._local_embeddings.embed_query(query)
    
    def unload_local_model(self):
        """Unload local model to free memory."""
        if self._local_embeddings is not None:
            logger.info("Unloading local embedding model")
            self._local_embeddings = None
            gc.collect()
    
    async def is_api_available(self) -> bool:
        """
        Check if HuggingFace API is available.
        
        Caches result for API_CHECK_INTERVAL seconds.
        
        Returns:
            True if API is available
        """
        import time
        
        current_time = time.time()
        
        # Return cached result if recent
        if self._api_available is not None and (current_time - self._api_check_time) < self.API_CHECK_INTERVAL:
            return self._api_available
        
        # Check API availability
        try:
            test_embedding = await self._generate_with_api(["test"])
            self._api_available = True
            self._api_check_time = current_time
            return True
        except Exception:
            self._api_available = False
            self._api_check_time = current_time
            return False


# Singleton instance
_embedding_service: Optional[EmbeddingService] = None


def get_embedding_service(strategy: EmbeddingStrategy = EmbeddingStrategy.AUTO) -> EmbeddingService:
    """Get or create embedding service singleton."""
    global _embedding_service
    if _embedding_service is None:
        _embedding_service = EmbeddingService(strategy=strategy)
    return _embedding_service
