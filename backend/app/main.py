"""FastAPI application entry point"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os
from dotenv import load_dotenv
from .routers import auth

# Load environment variables
load_dotenv()

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

# Include routers
app.include_router(auth.router)

@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "ScholarMate API", "version": "0.1.0"}

@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "scholarmate-backend"}
