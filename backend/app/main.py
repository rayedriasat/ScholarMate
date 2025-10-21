"""FastAPI application entry point"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = FastAPI(
    title="ScholarMate API",
    description="Backend API for ScholarMate - AI Research Workspace",
    version="0.1.0"
)

# CORS configuration
cors_origins = os.getenv("CORS_ORIGINS", "http://localhost:8080").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "ScholarMate API", "version": "0.1.0"}

@app.get("/api/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "scholarmate-backend"}
