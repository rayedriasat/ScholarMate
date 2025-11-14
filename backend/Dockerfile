# Use Python 3.12 slim image to reduce size
FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Install system dependencies needed for pdf2image, pytesseract, and poppler
# Keep the image small by cleaning up after installation
RUN apt-get update && apt-get install -y \
    tesseract-ocr \
    tesseract-ocr-eng \
    poppler-utils \
    && rm -rf /var/lib/apt/lists/*

# Install uv for faster dependency installation (10-100x faster than pip)
RUN pip install --no-cache-dir uv

# Copy pyproject.toml first to leverage Docker cache
COPY pyproject.toml .

# Install Python dependencies using uv
# --system: Install into the system Python (not a venv)
# --no-cache: Don't cache downloads to reduce image size
RUN uv pip install --system --no-cache .

# Copy the application code
COPY app/ ./app/

# Create directory for models if needed (sentence-transformers will download to cache)
RUN mkdir -p /root/.cache/huggingface

# Expose port (Defang will map this automatically)
EXPOSE 8000

# Set environment variables for production
ENV PYTHONUNBUFFERED=1
ENV HOST=0.0.0.0
ENV PORT=8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/api/health')"

# Run the application with uvicorn
# Use the app.main:app path since FastAPI app is in app/main.py
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

