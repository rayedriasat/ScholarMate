"""
GROQ AI Service for chat and embeddings.
Provides chat completion and text embedding using GROQ API.
"""

import os
import logging
from typing import List, Dict, Any, Optional
from groq import Groq, APIError, RateLimitError, APIConnectionError
from langchain_groq import ChatGroq

logger = logging.getLogger(__name__)


class GROQService:
    """Service for GROQ AI operations (chat and embeddings)."""
    
    def __init__(self):
        """Initialize GROQ service with API key from environment."""
        self.api_key = os.getenv("GROQ_API_KEY")
        if not self.api_key:
            logger.error("GROQ_API_KEY not found in environment variables")
            raise ValueError("GROQ_API_KEY is required")
        
        self.chat_model = os.getenv("GROQ_CHAT_MODEL", "llama-3.3-70b-versatile")
        self.embedding_model = os.getenv("GROQ_EMBEDDING_MODEL", "llama-3.3-70b-versatile")
        
        # Initialize GROQ client
        self.client = Groq(api_key=self.api_key)
        
        # Initialize LangChain GROQ for advanced features
        self.langchain_chat = ChatGroq(
            api_key=self.api_key,
            model=self.chat_model,
            temperature=0.7
        )
        
        logger.info(f"GROQ service initialized with chat model: {self.chat_model}")
    
    async def chat(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
        max_tokens: Optional[int] = None,
        stream: bool = False
    ) -> Dict[str, Any]:
        """
        Generate chat completion using GROQ API.
        
        Args:
            messages: List of message dicts with 'role' and 'content'
            temperature: Sampling temperature (0-2)
            max_tokens: Maximum tokens to generate
            stream: Whether to stream the response
            
        Returns:
            Dict with 'content' and 'usage' information
            
        Raises:
            APIError: For GROQ API errors
            RateLimitError: When rate limit is exceeded
        """
        try:
            logger.info(f"GROQ chat request with {len(messages)} messages")
            
            # Prepare request parameters
            params = {
                "model": self.chat_model,
                "messages": messages,
                "temperature": temperature,
            }
            
            if max_tokens:
                params["max_tokens"] = max_tokens
            
            # Make API call
            response = self.client.chat.completions.create(**params)
            
            # Extract response
            content = response.choices[0].message.content
            usage = {
                "prompt_tokens": response.usage.prompt_tokens,
                "completion_tokens": response.usage.completion_tokens,
                "total_tokens": response.usage.total_tokens
            }
            
            logger.info(f"GROQ chat completed. Tokens used: {usage['total_tokens']}")
            
            return {
                "content": content,
                "usage": usage,
                "model": self.chat_model,
                "finish_reason": response.choices[0].finish_reason
            }
            
        except RateLimitError as e:
            logger.error(f"GROQ rate limit exceeded: {str(e)}")
            raise
        except APIConnectionError as e:
            logger.error(f"GROQ API connection error: {str(e)}")
            raise
        except APIError as e:
            logger.error(f"GROQ API error: {str(e)}")
            raise
        except Exception as e:
            logger.error(f"Unexpected error in GROQ chat: {str(e)}")
            raise
    
    async def embed(self, texts: List[str]) -> List[List[float]]:
        """
        Generate embeddings for texts using GROQ.
        
        Note: GROQ doesn't have a dedicated embedding endpoint yet,
        so we use a workaround with chat completions to generate
        semantic representations.
        
        Args:
            texts: List of text strings to embed
            
        Returns:
            List of embedding vectors (list of floats)
            
        Raises:
            APIError: For GROQ API errors
        """
        try:
            logger.info(f"GROQ embedding request for {len(texts)} texts")
            
            # GROQ doesn't have native embeddings yet
            # This is a placeholder that should be updated when GROQ adds embedding support
            # For now, we'll return a simple hash-based representation
            # In production, you should use a proper embedding model
            
            logger.warning("GROQ embeddings not natively supported. Using placeholder.")
            
            # Placeholder: return zero vectors
            # TODO: Replace with actual embedding API when available
            embeddings = [[0.0] * 768 for _ in texts]
            
            logger.info(f"Generated {len(embeddings)} placeholder embeddings")
            
            return embeddings
            
        except Exception as e:
            logger.error(f"Error generating GROQ embeddings: {str(e)}")
            raise
    
    def test_connection(self) -> Dict[str, Any]:
        """
        Test GROQ API connectivity.
        
        Returns:
            Dict with connection status and details
        """
        try:
            # Simple test message
            test_messages = [
                {"role": "user", "content": "Say 'Hello' if you can hear me."}
            ]
            
            response = self.client.chat.completions.create(
                model=self.chat_model,
                messages=test_messages,
                max_tokens=10
            )
            
            return {
                "status": "success",
                "model": self.chat_model,
                "response": response.choices[0].message.content,
                "message": "GROQ API connection successful"
            }
            
        except Exception as e:
            logger.error(f"GROQ connection test failed: {str(e)}")
            return {
                "status": "error",
                "error": str(e),
                "message": "GROQ API connection failed"
            }


# Singleton instance
_groq_service: Optional[GROQService] = None


def get_groq_service() -> GROQService:
    """Get or create GROQ service singleton."""
    global _groq_service
    if _groq_service is None:
        _groq_service = GROQService()
    return _groq_service
