"""Middleware for request logging with request IDs"""
import time
import uuid
from typing import Callable
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from ..utils.logging_config import get_logger

logger = get_logger(__name__)


class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Middleware to log all API requests with request IDs and timing"""
    
    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        """
        Process request and log details
        
        Args:
            request: Incoming request
            call_next: Next middleware/handler
            
        Returns:
            Response from handler
        """
        # Generate unique request ID
        request_id = str(uuid.uuid4())
        
        # Store request ID in request state for access in handlers
        request.state.request_id = request_id
        
        # Extract user context if available (from headers or auth)
        user_id = request.headers.get("X-User-ID", "anonymous")
        
        # Start timing
        start_time = time.time()
        
        # Log incoming request
        logger.info(
            f"Request started: {request.method} {request.url.path}",
            extra={
                "request_id": request_id,
                "user_id": user_id,
                "method": request.method,
                "path": request.url.path,
                "query_params": str(request.query_params),
                "client_host": request.client.host if request.client else None,
                "user_agent": request.headers.get("user-agent"),
            }
        )
        
        # Process request
        try:
            response = await call_next(request)
            
            # Calculate duration
            duration_ms = (time.time() - start_time) * 1000
            
            # Log successful response
            logger.info(
                f"Request completed: {request.method} {request.url.path} - {response.status_code}",
                extra={
                    "request_id": request_id,
                    "user_id": user_id,
                    "method": request.method,
                    "path": request.url.path,
                    "status_code": response.status_code,
                    "duration_ms": round(duration_ms, 2),
                }
            )
            
            # Add request ID to response headers
            response.headers["X-Request-ID"] = request_id
            
            return response
            
        except Exception as e:
            # Calculate duration
            duration_ms = (time.time() - start_time) * 1000
            
            # Log error
            logger.error(
                f"Request failed: {request.method} {request.url.path} - {str(e)}",
                extra={
                    "request_id": request_id,
                    "user_id": user_id,
                    "method": request.method,
                    "path": request.url.path,
                    "duration_ms": round(duration_ms, 2),
                    "error": str(e),
                },
                exc_info=True
            )
            
            # Re-raise to let exception handlers deal with it
            raise
