"""FastAPI application entry point"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
import os
from dotenv import load_dotenv
from .routers import auth, test_logging
from .middleware import RequestLoggingMiddleware
from .utils.logging_config import setup_logging, get_logger
from .utils.exception_handlers import (
    http_exception_handler,
    validation_exception_handler,
    general_exception_handler,
)

# Load environment variables
load_dotenv()

# Setup logging
log_level = os.getenv("LOG_LEVEL", "INFO")
setup_logging(log_level)
logger = get_logger(__name__)

logger.info("Starting ScholarMate API", extra={"version": "0.1.0"})

app = FastAPI(
    title="ScholarMate API",
    description="Backend API for ScholarMate - AI Research Workspace",
    version="0.1.0"
)

# CORS configuration
# In development, allow all origins for easier testing across devices
if os.getenv("DEBUG", "False").lower() == "true":
    cors_origins = ["*"]
else:
    # In production, use specific origins from environment
    cors_origins = os.getenv("CORS_ORIGINS", "http://localhost:8080").split(",")
    cors_origins = [origin.strip() for origin in cors_origins]

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Add request logging middleware
app.add_middleware(RequestLoggingMiddleware)

# Register exception handlers
app.add_exception_handler(StarletteHTTPException, http_exception_handler)
app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(Exception, general_exception_handler)

# Include routers
app.include_router(auth.router)
app.include_router(test_logging.router)

logger.info("Application configured successfully")

@app.get("/")
async def root():
    """Root endpoint"""
    logger.debug("Root endpoint accessed")
    return {"message": "ScholarMate API", "version": "0.1.0"}

@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    logger.debug("Health check endpoint accessed")
    return {"status": "healthy", "service": "scholarmate-backend"}
