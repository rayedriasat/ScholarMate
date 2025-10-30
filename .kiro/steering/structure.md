---
inclusion: always
---

# Project Structure & Architecture

## Directory Structure

```
frontend/lib/
├── models/      # Data classes with fromJson/toJson
├── services/    # Business logic (AuthService, DriveService, CacheService)
├── screens/     # Full-page views (StatefulWidget)
├── widgets/     # Reusable components (prefer StatelessWidget)
└── main.dart    # Entry point

backend/app/
├── routers/     # API endpoints by domain (auth.py, files.py, ai.py)
├── services/    # Business logic (ocr_service.py, rag_service.py)
├── models/      # Pydantic request/response models
├── utils/       # Pure utility functions
└── main.py      # FastAPI app setup
```

## Naming Conventions

**Dart**: Files `snake_case.dart`, Classes `PascalCase`, functions/vars `camelCase`, constants `SCREAMING_SNAKE_CASE`
**Python**: Files `snake_case.py`, Classes `PascalCase`, functions/vars `snake_case`, constants `SCREAMING_SNAKE_CASE`

## Architecture Rules

### Offline-First Pattern (Critical)
1. Drift cache mirrors Google Drive structure
2. Offline queue stores pending operations
3. Auto-sync on reconnection
4. Conflict resolution: last-write-wins
5. Every feature MUST work offline or degrade gracefully

### Responsibility Split
**Frontend (Primary)**: Direct Google Drive ops, local caching, all UI, offline support
**Backend (Minimal)**: RAG/semantic search, OCR processing, AI orchestration, Supabase metadata

### Code Organization
- Business logic in `services/`, NOT in widgets
- Provider pattern for dependency injection
- Async/await for all I/O (never block UI thread)
- Pydantic models at all API boundaries

### Error Handling Pattern
1. Optimistic UI updates (immediate feedback)
2. Rollback on failure
3. Clear user actions on error
4. Never silent failures

## Security Requirements

- Google OAuth for authentication
- Encrypted token storage in Supabase
- Row Level Security (RLS) policies
- HTTPS only
- Never commit `.env` files (use `*.template`)
