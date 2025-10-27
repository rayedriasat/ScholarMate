# Backend Logging and Error Handling

## Overview

The ScholarMate backend implements comprehensive request logging and error handling with:
- Structured JSON logging
- Unique request IDs for tracing
- User context tracking
- Global exception handlers
- Request timing and metrics

## Components

### 1. Logging Configuration (`app/utils/logging_config.py`)

Provides structured JSON logging with custom formatter:

```python
from app.utils.logging_config import setup_logging, get_logger

# Setup logging (called in main.py)
setup_logging(log_level="INFO")

# Get logger in any module
logger = get_logger(__name__)
logger.info("Message", extra={"key": "value"})
```

**Log Format:**
```json
{
  "timestamp": "2025-10-27T17:53:55.863961Z",
  "level": "INFO",
  "logger": "app.main",
  "message": "Request completed",
  "request_id": "489d5b13-f964-4f4a-828c-dc6ce8bf993a",
  "user_id": "user123",
  "duration_ms": 45.23
}
```

### 2. Request Logging Middleware (`app/middleware/logging_middleware.py`)

Automatically logs all API requests with:
- Unique request ID (UUID)
- User context (from X-User-ID header)
- Request method and path
- Query parameters
- Client IP and user agent
- Response status code
- Request duration in milliseconds

**Request ID Header:**
All responses include `X-Request-ID` header for tracing.

### 3. Exception Handlers (`app/utils/exception_handlers.py`)

Three global exception handlers:

#### HTTP Exceptions (4xx, 5xx)
```json
{
  "error": {
    "message": "Resource not found",
    "status_code": 404,
    "request_id": "489d5b13-f964-4f4a-828c-dc6ce8bf993a"
  }
}
```

#### Validation Errors (422)
```json
{
  "error": {
    "message": "Validation error",
    "status_code": 422,
    "request_id": "489d5b13-f964-4f4a-828c-dc6ce8bf993a",
    "details": [
      {
        "loc": ["body", "email"],
        "msg": "field required",
        "type": "value_error.missing"
      }
    ]
  }
}
```

#### Unexpected Exceptions (500)
```json
{
  "error": {
    "message": "Internal server error",
    "status_code": 500,
    "request_id": "489d5b13-f964-4f4a-828c-dc6ce8bf993a"
  }
}
```

## Configuration

Set log level in `.env`:
```bash
LOG_LEVEL=INFO  # DEBUG, INFO, WARNING, ERROR, CRITICAL
```

## Testing

Run the test script to verify logging and error handling:

```bash
cd backend
uv run python test_logging.py
```

This tests:
- ✓ Successful requests (200)
- ✓ Client errors (400)
- ✓ Server errors (500)
- ✓ Request ID generation
- ✓ Error response format

## Usage in Endpoints

```python
from fastapi import APIRouter, HTTPException, Request
from ..utils.logging_config import get_logger

router = APIRouter()
logger = get_logger(__name__)

@router.get("/example")
async def example(request: Request):
    # Access request ID
    request_id = request.state.request_id
    
    # Log with context
    logger.info(
        "Processing example request",
        extra={
            "request_id": request_id,
            "user_id": "user123",
            "custom_field": "value"
        }
    )
    
    # Raise HTTP exceptions (automatically handled)
    if error_condition:
        raise HTTPException(
            status_code=400,
            detail="Invalid request"
        )
    
    return {"status": "ok"}
```

## Best Practices

1. **Always use structured logging** with `extra` parameter for context
2. **Include request_id** in all logs for tracing
3. **Use appropriate log levels**:
   - DEBUG: Detailed diagnostic info
   - INFO: General informational messages
   - WARNING: Warning messages (handled errors)
   - ERROR: Error messages (unexpected errors)
   - CRITICAL: Critical errors (system failures)
4. **Raise HTTPException** for expected errors (4xx)
5. **Let unexpected exceptions bubble up** for 500 handling
6. **Add user context** when available (user_id, email, etc.)

## Monitoring

All logs are output to stdout in JSON format, making them easy to:
- Parse with log aggregation tools (ELK, Splunk, etc.)
- Filter by request_id for tracing
- Monitor error rates and response times
- Debug issues with full context

## Example Log Output

```json
{"timestamp": "2025-10-27T17:53:55.863961Z", "level": "INFO", "logger": "app.middleware.logging_middleware", "message": "Request started: GET /api/health", "request_id": "489d5b13-f964-4f4a-828c-dc6ce8bf993a", "user_id": "anonymous", "method": "GET", "path": "/api/health", "query_params": "", "client_host": "127.0.0.1", "user_agent": "curl/7.68.0"}

{"timestamp": "2025-10-27T17:53:55.910234Z", "level": "INFO", "logger": "app.middleware.logging_middleware", "message": "Request completed: GET /api/health - 200", "request_id": "489d5b13-f964-4f4a-828c-dc6ce8bf993a", "user_id": "anonymous", "method": "GET", "path": "/api/health", "status_code": 200, "duration_ms": 46.27}
```
