"""FastAPI application entry point"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
import os
from dotenv import load_dotenv

# Load environment variables before importing any local modules
load_dotenv()

from .routers import auth, drive, annotations, ocr, ai, tags, sharing, ingestion, api_keys, metadata, embeddings, notebook_ai, collaboration, analytics, search, extraction, file_chat, payments
from .middleware import RequestLoggingMiddleware
from .utils.logging_config import setup_logging, get_logger
from .utils.exception_handlers import (
    http_exception_handler,
    validation_exception_handler,
    general_exception_handler,
)

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
    cors_origins_env = os.getenv("CORS_ORIGINS", "")
    if cors_origins_env:
        cors_origins = [origin.strip() for origin in cors_origins_env.split(",")]
    else:
        # Fallback to default production origins
        cors_origins = [
            "https://scholar-mate-nine.vercel.app",
            "http://localhost:8080",
            "http://localhost:3000"
        ]
    
logger.info(f"CORS enabled for origins: {cors_origins}")

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
app.include_router(drive.router)
app.include_router(annotations.router)
app.include_router(ocr.router)
app.include_router(ai.router)
app.include_router(tags.router)
app.include_router(sharing.router)
app.include_router(ingestion.router)
app.include_router(api_keys.router)
app.include_router(metadata.router)
app.include_router(embeddings.router)
app.include_router(notebook_ai.router)
app.include_router(collaboration.router)
app.include_router(analytics.router)
app.include_router(search.router)
app.include_router(extraction.router)
app.include_router(file_chat.router)
app.include_router(payments.router)

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
