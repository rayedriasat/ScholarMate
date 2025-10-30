---
inclusion: always
---

# Project Structure & Conventions

## Directory Layout

**Monorepo**: `frontend/` (Flutter) + `backend/` (FastAPI)

### Frontend (`frontend/lib/`)
- `models/` - Data classes with `fromJson`/`toJson`
- `services/` - Business logic (AuthService, DriveService, CacheService, etc.)
- `screens/` - Full-page views (typically StatefulWidget)
- `widgets/` - Reusable UI components (prefer StatelessWidget)
- `main.dart` - Entry point

### Backend (`backend/app/`)
- `routers/` - API endpoints grouped by domain (auth.py, files.py, ai.py)
- `services/` - Business logic (ocr_service.py, rag_service.py)
- `models/` - Pydantic request/response models
- `utils/` - Pure utility functions
- `main.py` - FastAPI app setup

## Code Conventions

### Dart (Frontend)
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Functions/variables: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`
- State: Provider pattern for dependency injection
- Separation: Business logic in services, not widgets

### Python (Backend)
- Files: `snake_case.py`
- Classes: `PascalCase`
- Functions/variables: `snake_case`
- Constants: `SCREAMING_SNAKE_CASE`
- Async: Use async/await for I/O operations
- Validation: Pydantic models for all API boundaries

## Architecture Patterns

### Offline-First (Frontend)
1. Drift sqlite3 cache mirrors Google Drive structure
2. Offline queue stores pending operations
3. Auto-sync on reconnection
4. Conflict resolution: last-write-wins

### Backend Responsibilities (Minimal)
- RAG indexing and semantic search
- OCR processing (DeepSeek online, Tesseract offline)
- AI query orchestration
- Supabase metadata management

### Frontend Responsibilities (Primary)
- Direct Google Drive operations
- Local caching and offline support
- All UI and user interactions

### Security
- Google OAuth for authentication
- Encrypted token storage in Supabase
- Row Level Security policies
- HTTPS only

## Configuration

- `.env` files: Never commit, use `*.template` for examples
- `pyproject.toml`: Python deps (managed by `uv add`)
- `pubspec.yaml`: Flutter deps (managed by `flutter pub add`)

## Development Rules

1. **Offline-first**: Every feature must work offline or degrade gracefully
2. **Minimize backend**: Frontend handles Drive directly
3. **Separation of concerns**: Services contain logic, UI components render
4. **Async patterns**: Use async/await, never block UI thread
5. **Error handling**: Provide clear user actions on failure
6. **Optimistic updates**: Update UI immediately, rollback on error
