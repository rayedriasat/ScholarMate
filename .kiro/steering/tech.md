# Technology Stack

## Architecture

Monorepo structure with separate frontend and backend:
- `frontend/` - Flutter cross-platform client
- `backend/` - FastAPI backend service

## Frontend (Flutter)

### Core Technologies
- **Framework**: Flutter 3.0+ (cross-platform: Android, iOS, Web, Windows, macOS, Linux)
- **State Management**: Provider
- **Local Database**: Drift (offline-first cache, works on all platforms including web)
- **PDF Viewer**: syncfusion_flutter_pdfviewer (viewing + annotations)
- **OCR (Offline)**: flutter_tesseract_ocr (Android offline mode)
- **Markdown**: flutter_markdown, markdown_editable_textinput (preview + editor)
- **Text-to-Speech**: flutter_tts
- **Authentication**: google_sign_in (v7+ with new API)
- **HTTP Client**: http package
- **Environment**: flutter_dotenv

### Package Management
Always use Flutter's package manager:
```bash
flutter pub add <package-name>
```

Never manually edit `pubspec.yaml` for dependencies.

### Common Commands
```bash
# Install dependencies
flutter pub get

# Run on different platforms
flutter run -d chrome        # Web
flutter run -d windows       # Windows
flutter run -d macos         # macOS
flutter run -d linux         # Linux
flutter run                  # Mobile (connected device/emulator)

# Testing
flutter test

# Build for production
flutter build apk            # Android
flutter build ios            # iOS
flutter build web            # Web
flutter build windows        # Windows
```

## Backend (FastAPI)

### Core Technologies
- **Framework**: FastAPI
- **Package Manager**: uv (with pyproject.toml)
- **Python Version**: 3.12+
- **Database Client**: Supabase Python SDK
- **OCR**: DeepSeek OCR (online mode, high accuracy with structure preservation)
- **Vector Database**: ChromaDB (self-hosted)
- **AI Orchestration**: LangChain (planned)
- **Encryption**: cryptography (Fernet)

### Package Management
Always use `uv` for package management:
```bash
uv add <package-name>
```

Never use `requirements.txt` or manually edit `pyproject.toml` dependencies.

### Common Commands
```bash
# Install dependencies
uv sync

# Run development server (with auto-reload)
uv run python run.py
# or
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Run production server
uv run uvicorn app.main:app --host 0.0.0.0 --port 8000

# Testing
uv run pytest
```

## Infrastructure

### Metadata & Realtime
- **Database**: Supabase PostgreSQL (free tier)
- **Realtime**: Supabase Realtime (free tier, no Edge Functions)
- **Authentication**: Google OAuth 2.0 (not Supabase Auth)

### File Storage
- **Primary Storage**: Google Drive (user-owned, app folder only)
- **Scope**: `drive.file` (access only to app-created files)
- **No Supabase Storage**: All files in Google Drive

### AI Providers
Pluggable provider layer supporting:
- OpenRouter (default)
- OpenAI
- Claude (Anthropic)
- Gemini (Google)
- Grok (xAI)

Users can provide their own API keys (stored encrypted).

## Non-Negotiable Rules

1. **Free-tier only**: No paid services or features
2. **No Supabase Edge Functions**: Use FastAPI backend instead
3. **No Supabase Storage**: Google Drive only
4. **Package managers**: `flutter pub add` for Flutter, `uv add` for Python
5. **Monorepo structure**: Keep frontend and backend in same repository
6. **Google OAuth only**: No Supabase Auth
7. **Offline-first**: All features must work offline with sync queue

## Environment Variables

Both frontend and backend use `.env` files (not committed to git):
- `backend/.env` - Backend configuration
- `frontend/.env` - Frontend configuration

Templates provided:
- `backend.env.template`
- `frontend.env.template`

## API Documentation

When backend is running:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
- Health check: http://localhost:8000/api/health
