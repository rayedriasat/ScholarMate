# ScholarMate

An offline-first, Google-Drive-backed AI research workspace for managing PDFs and Markdown files with annotation, scanning/OCR, read-aloud, semantic search (RAG), sharing, and realtime collaboration.

## 🎯 Vision

ScholarMate empowers researchers to:
- **Own their files**: All documents stored in your Google Drive
- **Work offline**: Full functionality without internet connection
- **AI-powered search**: Semantic search with RAG over your document library
- **Collaborate in realtime**: Share and annotate documents with your team
- **Stay cost-free**: Built entirely on free-tier services

## 🏗️ Architecture

```
ScholarMate (Monorepo)
├── frontend/          # Flutter cross-platform client
│   ├── lib/
│   │   ├── models/    # Data models
│   │   ├── services/  # Business logic services
│   │   ├── screens/   # UI screens
│   │   └── widgets/   # Reusable UI components
│   └── ...
├── backend/           # FastAPI backend service
│   ├── app/
│   │   ├── routers/   # API route handlers
│   │   ├── services/  # Business logic
│   │   ├── models/    # Data models
│   │   └── utils/     # Utility functions
│   └── pyproject.toml
└── README.md
```

### Tech Stack

**Frontend (Flutter)**
- Local cache: `drift` (cross-platform including web)
- PDF viewer: `syncfusion_flutter_pdfviewer`
- Text-to-speech: `flutter_tts`
- Camera/scanner: Flutter camera plugins

**Backend (FastAPI)**
- Package manager: `uv` + `pyproject.toml`
- OCR: Tesseract or EasyOCR
- Vector DB: ChromaDB (self-hosted)
- AI: Pluggable provider layer (OpenRouter, OpenAI, Claude, Gemini, Grok)

**Infrastructure**
- Metadata DB: Supabase PostgreSQL (free tier)
- File storage: Google Drive (user-owned)
- Realtime: Supabase Realtime (free tier)

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** (3.0+): [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Python** (3.10+): [Install Python](https://www.python.org/downloads/)
- **uv** package manager: [Install uv](https://docs.astral.sh/uv/)
- **Google Cloud Console** account for OAuth credentials
- **Supabase** account (free tier)

### Setup Instructions

#### 1. Clone the Repository

```bash
git clone <repository-url>
cd scholarmate
```

#### 2. Backend Setup

```bash
cd backend

# Copy environment template
cp ../backend.env.template .env

# Edit .env with your credentials
# - Supabase URL and keys
# - Google OAuth credentials
# - AI provider API keys
# - Generate encryption key: python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"

# Install dependencies (uv will create virtual environment automatically)
uv sync

# Run the backend
uv run uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The backend will be available at `http://localhost:8000`
- API docs: `http://localhost:8000/docs`
- Health check: `http://localhost:8000/api/health`

#### 3. Frontend Setup

```bash
cd frontend

# Copy environment template
cp ../frontend.env.template .env

# Edit .env with your credentials
# - Google OAuth credentials
# - Backend API URL
# - Supabase URL and anon key

# Install dependencies
flutter pub get

# Run on your preferred platform
flutter run -d chrome --web-port=8080 # Chrome
flutter run -d edge --web-port=8080   # Edge 
flutter run -d windows                # Windows
flutter run -d macos                  # macOS
flutter run -d linux                  # Linux
flutter run                           # Mobile (connected device/emulator)
```

#### 4. Deploy to Vercel (Web Only)

Deploy the prebuilt Flutter web app to Vercel:

```bash
# Build the web app locally
cd frontend
flutter build web --release --web-renderer canvaskit

# Commit the build folder (it's force-included in git)
cd ..
git add frontend/build/web
git commit -m "Build web app for deployment"
git push

# Deploy to Vercel
vercel --prod
```

**Setup**:
1. Set environment variables in Vercel dashboard (see `.env.vercel.example`)
2. Update `GOOGLE_REDIRECT_URI` to your Vercel URL
3. Add Vercel URL to Google OAuth authorized redirect URIs

**Documentation**: See [DOCUMENTATION_INDEX.md](DOCUMENTATION_INDEX.md) for complete guide
- 🚀 First deployment: [FIRST_DEPLOYMENT.md](FIRST_DEPLOYMENT.md)
- ⚡ Quick start: [VERCEL_QUICK_START.md](VERCEL_QUICK_START.md)
- 📚 Full guide: [VERCEL_DEPLOYMENT.md](VERCEL_DEPLOYMENT.md)
- 📋 Quick reference: [QUICK_REFERENCE.md](QUICK_REFERENCE.md)

The app automatically detects Vercel and fetches config from the serverless function
```

### Google OAuth Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable Google Drive API
4. Configure OAuth consent screen
5. Create OAuth 2.0 credentials:
   - Web application (for backend)
   - iOS (for iOS app)
   - Android (for Android app)
6. Add authorized redirect URIs:
   - `http://localhost:8080/auth/callback` (development)
   - Your production URLs
7. Request `drive.file` scope for app folder access
8. Copy Client ID and Client Secret to your `.env` files

### Supabase Setup

1. Create a new project at [Supabase](https://supabase.com/)
2. Go to Project Settings → API
3. Copy the following to your `.env` files:
   - Project URL → `SUPABASE_URL`
   - `anon` `public` key → `SUPABASE_KEY` / `SUPABASE_ANON_KEY`
   - `service_role` `secret` key → `SUPABASE_SERVICE_KEY`
4. Run the database schema from `.kiro/specs/scholarmate/design.md`
5. Enable Realtime for required tables

## 📋 Features

### Core Features
- ✅ **Google OAuth Authentication**: Secure sign-in with Google
- ✅ **Google Drive Integration**: All files stored in your Drive
- ✅ **Offline-First**: Full functionality without internet
- ✅ **PDF Viewing**: High-performance PDF rendering
- ✅ **Annotations**: Highlight, underline, and comment on PDFs
- ✅ **Document Scanning**: Camera-based OCR for paper documents
- ✅ **AI Chat**: Semantic search with RAG over your library
- ✅ **Read Aloud**: Text-to-speech for PDFs
- ✅ **Sharing**: Role-based permissions (Viewer/Editor)
- ✅ **Public Links**: View-only sharing without authentication
- ✅ **Realtime Collaboration**: Live annotations and file operations
- ✅ **Presence Tracking**: See who's viewing documents

### Development Phases

The project follows an incremental development approach with 18 testable phases:

1. Foundation & Authentication
2. Drive Integration & File Browsing
3. Offline Foundation & Local Cache
4. PDF Viewing
5. PDF Annotations
6. Backend Infrastructure & Supabase
7. Annotation Sync
8. OCR & Document Scanning
9. AI Provider Abstraction
10. RAG Indexing
11. AI Chat with RAG
12. Sharing & Permissions
13. Public Link Sharing
14. Realtime Annotations
15. Realtime File Operations
16. Presence & Activity
17. Read Aloud
18. Performance & Polish

See `.kiro/specs/scholarmate/tasks.md` for detailed implementation plan.

## 🧪 Testing

### Backend Tests
```bash
cd backend
uv run pytest
```

### Frontend Tests
```bash
cd frontend
flutter test
```

## 🚀 Deployment

### Production Setup
- **Frontend**: Vercel (https://scholar-mate-nine.vercel.app)
- **Backend**: Render.com (https://scholarmate-backend.onrender.com)

### Quick Deploy
```bash
# Deploy backend to Render
# See DEPLOY_TO_RENDER.md for step-by-step guide
git push origin main
# Then follow Render Blueprint setup

# Frontend auto-deploys to Vercel on push
```

### Deployment Guides
- **DEPLOY_TO_RENDER.md** - Step-by-step backend deployment
- **RENDER_QUICK_START.md** - Quick reference
- **FULL_DEPLOYMENT_GUIDE.md** - Complete frontend + backend guide
- **RENDER_CHECKLIST.md** - Deployment checklist

## 📚 Documentation

- **Requirements**: `.kiro/specs/scholarmate/requirements.md`
- **Design**: `.kiro/specs/scholarmate/design.md`
- **Tasks**: `.kiro/specs/scholarmate/tasks.md`
- **API Docs**: 
  - Local: `http://localhost:8000/docs`
  - Production: `https://scholarmate-backend.onrender.com/docs`

## 🔒 Security

- All OAuth tokens encrypted at rest
- Row Level Security (RLS) on Supabase
- HTTPS-only communication
- Least-privilege OAuth scopes
- Audit logging for sensitive operations

## 🤝 Contributing

This project follows a spec-driven development approach. Please refer to the specification documents in `.kiro/specs/scholarmate/` before contributing.

## 📄 License

[Add your license here]

## 🙏 Acknowledgments

- Built with Flutter and FastAPI
- Powered by Supabase and Google Drive
- AI capabilities via OpenRouter and other providers
