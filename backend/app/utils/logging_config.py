"""Logging configuration for structured logging with request IDs"""
import logging
import sys
from datetime import datetime
from typing import Any, Dict
import json


class StructuredFormatter(logging.Formatter):
    """Custom formatter that outputs structured JSON logs"""
    
    def format(self, record: logging.LogRecord) -> str:
        """Format log record as JSON"""
        log_data: Dict[str, Any] = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        
        # Add request ID if available
        if hasattr(record, "request_id"):
            log_data["request_id"] = record.request_id
        
        # Add user context if available
        if hasattr(record, "user_id"):
            log_data["user_id"] = record.user_id
        
        # Add extra fields
        if hasattr(record, "extra"):
            log_data.update(record.extra)
        
        # Add exception info if present
        if record.exc_info:
            log_data["exception"] = self.formatException(record.exc_info)
        
        return json.dumps(log_data)


def setup_logging(log_level: str = "INFO") -> None:
    """
    Configure application logging
    
    Args:
        log_level: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
    """
    # Create root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, log_level.upper()))
    
    # Remove existing handlers
    root_logger.handlers.clear()
    
    # Create console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(getattr(logging, log_level.upper()))
    
    # Use structured formatter
    formatter = StructuredFormatter()
    console_handler.setFormatter(formatter)
    
    # Add handler to root logger
    root_logger.addHandler(console_handler)
    
    # Reduce noise from third-party libraries
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("httpcore").setLevel(logging.WARNING)


def get_logger(name: str) -> logging.Logger:
    """
    Get a logger instance
    
    Args:
        name: Logger name (typically __name__)
        
    Returns:
        Logger instance
    """
    return logging.getLogger(name)
