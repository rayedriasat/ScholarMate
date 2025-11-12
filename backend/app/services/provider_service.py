"""
Multi-Provider AI Service.
Provides unified interface for multiple AI providers (GROQ, OpenAI, Anthropic, etc.)
"""

import os
import logging
from typing import List, Dict, Any, Optional
from abc import ABC, abstractmethod

# Provider-specific imports
from groq import Groq, APIError as GroqAPIError
from openai import OpenAI, APIError as OpenAIAPIError
from anthropic import Anthropic, APIError as AnthropicAPIError

logger = logging.getLogger(__name__)


class AIProvider(ABC):
    """Abstract base class for AI providers."""
    
    @abstractmethod
    async def chat(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
        max_tokens: Optional[int] = None
    ) -> Dict[str, Any]:
        """Generate chat completion."""
        pass
    
    @abstractmethod
    async def validate_key(self) -> Dict[str, Any]:
        """Validate API key with a lightweight test call."""
        pass
    
    @abstractmethod
    def get_provider_name(self) -> str:
        """Get provider name."""
        pass


class GroqProvider(AIProvider):
    """GROQ AI provider implementation."""
    
    def __init__(self, api_key: str, model: str = "llama-3.3-70b-versatile"):
        self.api_key = api_key
        self.model = model
        self.client = Groq(api_key=api_key)
    
    async def chat(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
        max_tokens: Optional[int] = None
    ) -> Dict[str, Any]:
        """Generate chat completion using GROQ."""
        try:
            params = {
                "model": self.model,
                "messages": messages,
                "temperature": temperature,
            }
            if max_tokens:
                params["max_tokens"] = max_tokens
            
            response = self.client.chat.completions.create(**params)
            
            return {
                "content": response.choices[0].message.content,
                "usage": {
                    "prompt_tokens": response.usage.prompt_tokens,
                    "completion_tokens": response.usage.completion_tokens,
                    "total_tokens": response.usage.total_tokens
                },
                "model": self.model,
                "finish_reason": response.choices[0].finish_reason
            }
        except Exception as e:
            logger.error(f"GROQ chat error: {str(e)}")
            raise
    
    async def validate_key(self) -> Dict[str, Any]:
        """Validate GROQ API key."""
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[{"role": "user", "content": "Hi"}],
                max_tokens=5
            )
            return {
                "is_valid": True,
                "model_info": {"model": self.model, "response": response.choices[0].message.content}
            }
        except GroqAPIError as e:
            return {"is_valid": False, "error": str(e)}
        except Exception as e:
            return {"is_valid": False, "error": f"Validation failed: {str(e)}"}
    
    def get_provider_name(self) -> str:
        return "groq"


class OpenAIProvider(AIProvider):
    """OpenAI provider implementation."""
    
    def __init__(self, api_key: str, model: str = "gpt-4o-mini"):
        self.api_key = api_key
        self.model = model
        self.client = OpenAI(api_key=api_key)
    
    async def chat(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
        max_tokens: Optional[int] = None
    ) -> Dict[str, Any]:
        """Generate chat completion using OpenAI."""
        try:
            params = {
                "model": self.model,
                "messages": messages,
                "temperature": temperature,
            }
            if max_tokens:
                params["max_tokens"] = max_tokens
            
            response = self.client.chat.completions.create(**params)
            
            return {
                "content": response.choices[0].message.content,
                "usage": {
                    "prompt_tokens": response.usage.prompt_tokens,
                    "completion_tokens": response.usage.completion_tokens,
                    "total_tokens": response.usage.total_tokens
                },
                "model": self.model,
                "finish_reason": response.choices[0].finish_reason
            }
        except Exception as e:
            logger.error(f"OpenAI chat error: {str(e)}")
            raise
    
    async def validate_key(self) -> Dict[str, Any]:
        """Validate OpenAI API key."""
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[{"role": "user", "content": "Hi"}],
                max_tokens=5
            )
            return {
                "is_valid": True,
                "model_info": {"model": self.model, "response": response.choices[0].message.content}
            }
        except OpenAIAPIError as e:
            return {"is_valid": False, "error": str(e)}
        except Exception as e:
            return {"is_valid": False, "error": f"Validation failed: {str(e)}"}
    
    def get_provider_name(self) -> str:
        return "openai"


class AnthropicProvider(AIProvider):
    """Anthropic (Claude) provider implementation."""
    
    def __init__(self, api_key: str, model: str = "claude-3-5-sonnet-20241022"):
        self.api_key = api_key
        self.model = model
        self.client = Anthropic(api_key=api_key)
    
    async def chat(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
        max_tokens: Optional[int] = None
    ) -> Dict[str, Any]:
        """Generate chat completion using Anthropic."""
        try:
            # Anthropic requires system messages separately
            system_msg = None
            chat_messages = []
            
            for msg in messages:
                if msg["role"] == "system":
                    system_msg = msg["content"]
                else:
                    chat_messages.append(msg)
            
            params = {
                "model": self.model,
                "messages": chat_messages,
                "temperature": temperature,
                "max_tokens": max_tokens or 1024
            }
            if system_msg:
                params["system"] = system_msg
            
            response = self.client.messages.create(**params)
            
            return {
                "content": response.content[0].text,
                "usage": {
                    "prompt_tokens": response.usage.input_tokens,
                    "completion_tokens": response.usage.output_tokens,
                    "total_tokens": response.usage.input_tokens + response.usage.output_tokens
                },
                "model": self.model,
                "finish_reason": response.stop_reason
            }
        except Exception as e:
            logger.error(f"Anthropic chat error: {str(e)}")
            raise
    
    async def validate_key(self) -> Dict[str, Any]:
        """Validate Anthropic API key."""
        try:
            response = self.client.messages.create(
                model=self.model,
                messages=[{"role": "user", "content": "Hi"}],
                max_tokens=5
            )
            return {
                "is_valid": True,
                "model_info": {"model": self.model, "response": response.content[0].text}
            }
        except AnthropicAPIError as e:
            return {"is_valid": False, "error": str(e)}
        except Exception as e:
            return {"is_valid": False, "error": f"Validation failed: {str(e)}"}
    
    def get_provider_name(self) -> str:
        return "anthropic"


class OpenRouterProvider(AIProvider):
    """OpenRouter provider implementation."""
    
    def __init__(self, api_key: str, model: str = "openai/gpt-4o-mini"):
        self.api_key = api_key
        self.model = model
        # OpenRouter uses OpenAI-compatible API
        self.client = OpenAI(
            api_key=api_key,
            base_url="https://openrouter.ai/api/v1"
        )
    
    async def chat(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
        max_tokens: Optional[int] = None
    ) -> Dict[str, Any]:
        """Generate chat completion using OpenRouter."""
        try:
            params = {
                "model": self.model,
                "messages": messages,
                "temperature": temperature,
            }
            if max_tokens:
                params["max_tokens"] = max_tokens
            
            response = self.client.chat.completions.create(**params)
            
            return {
                "content": response.choices[0].message.content,
                "usage": {
                    "prompt_tokens": response.usage.prompt_tokens,
                    "completion_tokens": response.usage.completion_tokens,
                    "total_tokens": response.usage.total_tokens
                },
                "model": self.model,
                "finish_reason": response.choices[0].finish_reason
            }
        except Exception as e:
            logger.error(f"OpenRouter chat error: {str(e)}")
            raise
    
    async def validate_key(self) -> Dict[str, Any]:
        """Validate OpenRouter API key."""
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[{"role": "user", "content": "Hi"}],
                max_tokens=5
            )
            return {
                "is_valid": True,
                "model_info": {"model": self.model, "response": response.choices[0].message.content}
            }
        except Exception as e:
            return {"is_valid": False, "error": f"Validation failed: {str(e)}"}
    
    def get_provider_name(self) -> str:
        return "openrouter"


class GoogleProvider(AIProvider):
    """Google (Gemini) provider implementation."""
    
    def __init__(self, api_key: str, model: str = "gemini-1.5-flash"):
        self.api_key = api_key
        self.model = model
        self.base_url = "https://generativelanguage.googleapis.com/v1beta"
    
    async def chat(
        self,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
        max_tokens: Optional[int] = None
    ) -> Dict[str, Any]:
        """Generate chat completion using Google Gemini."""
        try:
            import requests
            
            # Convert messages to Gemini format
            contents = []
            for msg in messages:
                role = "user" if msg["role"] in ["user", "system"] else "model"
                contents.append({
                    "role": role,
                    "parts": [{"text": msg["content"]}]
                })
            
            url = f"{self.base_url}/models/{self.model}:generateContent?key={self.api_key}"
            
            payload = {
                "contents": contents,
                "generationConfig": {
                    "temperature": temperature,
                    "maxOutputTokens": max_tokens or 1024
                }
            }
            
            response = requests.post(url, json=payload)
            response.raise_for_status()
            data = response.json()
            
            content = data["candidates"][0]["content"]["parts"][0]["text"]
            
            # Gemini doesn't always return token counts
            usage_metadata = data.get("usageMetadata", {})
            
            return {
                "content": content,
                "usage": {
                    "prompt_tokens": usage_metadata.get("promptTokenCount", 0),
                    "completion_tokens": usage_metadata.get("candidatesTokenCount", 0),
                    "total_tokens": usage_metadata.get("totalTokenCount", 0)
                },
                "model": self.model,
                "finish_reason": data["candidates"][0].get("finishReason", "STOP")
            }
        except Exception as e:
            logger.error(f"Google chat error: {str(e)}")
            raise
    
    async def validate_key(self) -> Dict[str, Any]:
        """Validate Google API key."""
        try:
            import requests
            
            url = f"{self.base_url}/models/{self.model}:generateContent?key={self.api_key}"
            
            payload = {
                "contents": [{
                    "role": "user",
                    "parts": [{"text": "Hi"}]
                }],
                "generationConfig": {
                    "maxOutputTokens": 5
                }
            }
            
            response = requests.post(url, json=payload)
            response.raise_for_status()
            data = response.json()
            
            content = data["candidates"][0]["content"]["parts"][0]["text"]
            
            return {
                "is_valid": True,
                "model_info": {"model": self.model, "response": content}
            }
        except Exception as e:
            return {"is_valid": False, "error": f"Validation failed: {str(e)}"}
    
    def get_provider_name(self) -> str:
        return "google"


class ProviderFactory:
    """Factory for creating AI provider instances."""
    
    PROVIDER_CONFIGS = {
        "groq": {
            "class": GroqProvider,
            "display_name": "GROQ",
            "default_model": "llama-3.3-70b-versatile",
            "supports_chat": True,
            "supports_embeddings": False,
            "api_key_format": "gsk_*",
            "docs_url": "https://console.groq.com/docs"
        },
        "openai": {
            "class": OpenAIProvider,
            "display_name": "OpenAI",
            "default_model": "gpt-4o-mini",
            "supports_chat": True,
            "supports_embeddings": True,
            "api_key_format": "sk-*",
            "docs_url": "https://platform.openai.com/docs"
        },
        "anthropic": {
            "class": AnthropicProvider,
            "display_name": "Anthropic (Claude)",
            "default_model": "claude-3-5-sonnet-20241022",
            "supports_chat": True,
            "supports_embeddings": False,
            "api_key_format": "sk-ant-*",
            "docs_url": "https://docs.anthropic.com"
        },
        "openrouter": {
            "class": OpenRouterProvider,
            "display_name": "OpenRouter",
            "default_model": "openai/gpt-4o-mini",
            "supports_chat": True,
            "supports_embeddings": False,
            "api_key_format": "sk-or-*",
            "docs_url": "https://openrouter.ai/docs"
        },
        "google": {
            "class": GoogleProvider,
            "display_name": "Google (Gemini)",
            "default_model": "gemini-1.5-flash",
            "supports_chat": True,
            "supports_embeddings": False,
            "api_key_format": "AIza*",
            "docs_url": "https://ai.google.dev/docs"
        }
    }
    
    @classmethod
    def create_provider(cls, provider_name: str, api_key: str, model: Optional[str] = None) -> AIProvider:
        """
        Create provider instance.
        
        Args:
            provider_name: Provider name (groq, openai, anthropic)
            api_key: API key for the provider
            model: Optional model override
            
        Returns:
            AIProvider instance
            
        Raises:
            ValueError: If provider not supported
        """
        if provider_name not in cls.PROVIDER_CONFIGS:
            raise ValueError(f"Unsupported provider: {provider_name}")
        
        config = cls.PROVIDER_CONFIGS[provider_name]
        provider_class = config["class"]
        default_model = model or config["default_model"]
        
        return provider_class(api_key=api_key, model=default_model)
    
    @classmethod
    def get_supported_providers(cls) -> List[Dict[str, Any]]:
        """Get list of supported providers with metadata."""
        return [
            {
                "name": name,
                "display_name": config["display_name"],
                "supports_chat": config["supports_chat"],
                "supports_embeddings": config["supports_embeddings"],
                "default_chat_model": config["default_model"] if config["supports_chat"] else None,
                "default_embedding_model": None,  # TODO: Add embedding models
                "api_key_format": config["api_key_format"],
                "docs_url": config["docs_url"]
            }
            for name, config in cls.PROVIDER_CONFIGS.items()
        ]
    
    @classmethod
    def is_supported(cls, provider_name: str) -> bool:
        """Check if provider is supported."""
        return provider_name in cls.PROVIDER_CONFIGS


# Singleton for system default provider
_default_provider: Optional[AIProvider] = None


def get_default_provider() -> AIProvider:
    """Get system default provider (GROQ from env)."""
    global _default_provider
    if _default_provider is None:
        api_key = os.getenv("GROQ_API_KEY")
        if not api_key:
            raise ValueError("GROQ_API_KEY not set for default provider")
        _default_provider = GroqProvider(api_key=api_key)
    return _default_provider
