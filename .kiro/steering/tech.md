---
inclusion: always
---

# Technology Stack

## Package Management (Critical)

**Flutter**: ONLY use `flutter pub add <package>` - never manually edit `pubspec.yaml`
**Python**: ONLY use `uv add <package>` - never use `requirements.txt` or manually edit `pyproject.toml`

## Frontend Stack (Flutter 3.0+)

- **State**: Provider pattern for dependency injection
- **Database**: Drift (sqlite3, offline-first, all platforms including web)
- **PDF**: syncfusion_flutter_pdfviewer (viewing + annotations)
- **OCR**: flutter_tesseract_ocr (offline Android only)
- **Markdown**: flutter_markdown, markdown_editable_textinput
- **Auth**: google_sign_in v7+ (new API)
- **TTS**: flutter_tts
- **HTTP**: http package
- **Env**: flutter_dotenv

## Backend Stack (FastAPI)

- **Framework**: FastAPI with async/await
- **Python**: 3.12+
- **Package Manager**: uv (with pyproject.toml)
- **Database**: Supabase Python SDK (PostgreSQL + Realtime)
- **OCR**: DeepSeek OCR (online, high accuracy)
- **Vector DB**: ChromaDB (self-hosted)
- **Encryption**: cryptography (Fernet)

## Infrastructure Constraints

**Storage**: Google Drive ONLY (app folder scope `drive.file`) - NO Supabase Storage
**Auth**: Google OAuth 2.0 ONLY - NO Supabase Auth
**Backend**: FastAPI ONLY - NO Supabase Edge Functions
**Cost**: Free tier ONLY - NO paid services

## AI Providers (Pluggable)

OpenRouter (default), OpenAI, Claude, Gemini, Grok - user-provided API keys (encrypted)

## Common Commands

```bash
# Flutter
flutter pub get                    # Install deps
flutter run -d chrome              # Run web
flutter run -d windows             # Run Windows
flutter test                       # Run tests
flutter build apk                  # Build Android

# Python (backend)
uv sync                            # Install deps
uv run python run.py               # Dev server (auto-reload)
uv run pytest                      # Run tests
```

## Environment Files

`.env` files (never commit):
- `backend/.env` - Backend config
- `frontend/.env` - Frontend config
- Templates: `backend.env.template`, `frontend.env.template`

## API Endpoints (when backend running)

- Swagger: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
- Health: http://localhost:8000/api/health
