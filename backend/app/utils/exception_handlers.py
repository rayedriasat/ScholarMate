"""Global exception handlers for FastAPI"""
from fastapi import Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from .logging_config import get_logger

logger = get_logger(__name__)


async def http_exception_handler(request: Request, exc: StarletteHTTPException) -> JSONResponse:
    """
    Handle HTTP exceptions
    
    Args:
        request: Request that caused the exception
        exc: HTTP exception
        
    Returns:
        JSON response with error details
    """
    request_id = getattr(request.state, "request_id", "unknown")
    user_id = request.headers.get("X-User-ID", "anonymous")
    
    logger.warning(
        f"HTTP exception: {exc.status_code} - {exc.detail}",
        extra={
            "request_id": request_id,
            "user_id": user_id,
            "status_code": exc.status_code,
            "path": request.url.path,
            "detail": exc.detail,
        }
    )
    
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "message": exc.detail,
                "status_code": exc.status_code,
                "request_id": request_id,
            }
        },
        headers={"X-Request-ID": request_id}
    )


async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    """
    Handle request validation errors
    
    Args:
        request: Request that caused the exception
        exc: Validation error
        
    Returns:
        JSON response with validation error details
    """
    request_id = getattr(request.state, "request_id", "unknown")
    user_id = request.headers.get("X-User-ID", "anonymous")
    
    # Convert errors to JSON-serializable format
    errors = exc.errors()
    serializable_errors = []
    for error in errors:
        serializable_error = {
            "type": error.get("type"),
            "loc": error.get("loc"),
            "msg": error.get("msg"),
            "input": error.get("input"),
        }
        # Convert ctx to serializable format (ctx may contain non-serializable objects)
        if "ctx" in error:
            ctx = error["ctx"]
            serializable_ctx = {}
            for key, value in ctx.items():
                # Convert any non-serializable values to strings
                try:
                    import json
                    json.dumps(value)
                    serializable_ctx[key] = value
                except (TypeError, ValueError):
                    serializable_ctx[key] = str(value)
            serializable_error["ctx"] = serializable_ctx
        serializable_errors.append(serializable_error)
    
    logger.warning(
        f"Validation error: {exc.errors()}",
        extra={
            "request_id": request_id,
            "user_id": user_id,
            "path": request.url.path,
        }
    )
    
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": {
                "message": "Validation error",
                "status_code": status.HTTP_422_UNPROCESSABLE_ENTITY,
                "request_id": request_id,
                "details": serializable_errors,
            }
        },
        headers={"X-Request-ID": request_id}
    )


async def general_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """
    Handle unexpected exceptions
    
    Args:
        request: Request that caused the exception
        exc: Unexpected exception
        
    Returns:
        JSON response with generic error message
    """
    request_id = getattr(request.state, "request_id", "unknown")
    user_id = request.headers.get("X-User-ID", "anonymous")
    
    logger.error(
        f"Unexpected error: {str(exc)}",
        extra={
            "request_id": request_id,
            "user_id": user_id,
            "path": request.url.path,
            "exception_type": type(exc).__name__,
        },
        exc_info=True
    )
    
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": {
                "message": "Internal server error",
                "status_code": status.HTTP_500_INTERNAL_SERVER_ERROR,
                "request_id": request_id,
            }
        },
        headers={"X-Request-ID": request_id}
    )
