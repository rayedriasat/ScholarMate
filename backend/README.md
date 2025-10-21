# ScholarMate Backend

FastAPI backend service for ScholarMate, handling OCR, RAG indexing, and AI queries.

## Setup

1. Copy environment template:
```bash
cp ../.env.template .env
```

2. Edit `.env` with your credentials

3. Install dependencies:
```bash
uv sync
```

## Running the Server

### Development Mode (with auto-reload)
```bash
uv run python run.py
```

Or:
```bash
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Production Mode
```bash
uv run uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## API Documentation

Once the server is running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Project Structure

```
backend/
├── app/
│   ├── routers/      # API route handlers
│   ├── services/     # Business logic services
│   ├── models/       # Pydantic models
│   ├── utils/        # Utility functions
│   └── main.py       # FastAPI application
├── pyproject.toml    # Dependencies (managed by uv)
├── run.py            # Development server runner
└── .env              # Environment variables (not in git)
```

## Adding Dependencies

Use `uv` to add new packages:
```bash
uv add <package-name>
```

Example:
```bash
uv add langchain chromadb
```

## Testing

```bash
uv run pytest
```
