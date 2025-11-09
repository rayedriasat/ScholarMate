#!/bin/bash
# Render startup script with memory optimization

set -e  # Exit on error

echo "Starting ScholarMate Backend (Memory-Optimized)..."

# Set Python memory limits for better garbage collection
export PYTHONUNBUFFERED=1
export MALLOC_TRIM_THRESHOLD_=100000

# Pre-download sentence-transformers model (optional, helps with first request)
# Skip if it causes memory issues during startup
echo "Pre-loading embedding model (optional)..."
python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')" 2>/dev/null || echo "Skipping model pre-load (will load on first use)"

# Start uvicorn with memory-optimized settings
echo "Starting uvicorn server..."
exec uvicorn app.main:app \
  --host 0.0.0.0 \
  --port ${PORT:-8000} \
  --workers 1 \
  --timeout-keep-alive 75 \
  --limit-concurrency 10 \
  --backlog 50 \
  --log-level info
