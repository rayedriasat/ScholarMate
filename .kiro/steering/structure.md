# Project Structure

## Monorepo Layout

```
ScholarMate/
├── frontend/              # Flutter cross-platform client
├── backend/               # FastAPI backend service
├── .kiro/                 # Kiro IDE configuration
│   ├── steering/          # AI assistant steering rules
│   └── specs/             # Project specifications
├── README.md              # Main project documentation
├── description.md         # Detailed project description
├── backend.env.template   # Backend environment template
├── frontend.env.template  # Frontend environment template
├── start-backend.bat      # Windows backend launcher
└── start-frontend.bat     # Windows frontend launcher
```

## Frontend Structure

```
frontend/
├── lib/
│   ├── models/            # Data models (User, File, Folder, Annotation, etc.)
│   ├── services/          # Business logic services
│   │                      # (AuthService, DriveService, CacheService, etc.)
│   ├── screens/           # UI screens (LoginScreen, HomeScreen, PDFViewer, etc.)
│   ├── widgets/           # Reusable UI components
│   └── main.dart          # Application entry point
├── test/                  # Unit and widget tests
├── assets/                # Images, fonts, and other assets
├── android/               # Android-specific configuration
├── ios/                   # iOS-specific configuration
├── web/                   # Web-specific configuration
├── windows/               # Windows-specific configuration
├── macos/                 # macOS-specific configuration
├── linux/                 # Linux-specific configuration
├── pubspec.yaml           # Flutter dependencies
├── .env                   # Environment variables (not in git)
└── README.md              # Frontend documentation
```

### Frontend Conventions

- **Models**: Plain Dart classes with `fromJson`/`toJson` methods
- **Services**: Business logic separated from UI, injectable via Provider
- **Screens**: Full-page views, typically stateful widgets
- **Widgets**: Reusable components, prefer stateless when possible
- **State Management**: Provider pattern for dependency injection and state

## Backend Structure

```
backend/
├── app/
│   ├── routers/           # API route handlers (auth.py, files.py, ai.py, etc.)
│   ├── services/          # Business logic services
│   │                      # (ocr_service.py, rag_service.py, etc.)
│   ├── models/            # Pydantic models for request/response
│   ├── utils/             # Utility functions (encryption, validation, etc.)
│   └── main.py            # FastAPI application setup
├── migrations/            # Database migrations (if needed)
├── pyproject.toml         # Python dependencies (managed by uv)
├── uv.lock                # Locked dependency versions
├── run.py                 # Development server runner
├── .env                   # Environment variables (not in git)
└── README.md              # Backend documentation
```

### Backend Conventions

- **Routers**: Group related endpoints (e.g., `/api/auth/*`, `/api/files/*`)
- **Services**: Business logic separated from route handlers
- **Models**: Pydantic models for validation and serialization
- **Utils**: Pure functions for common operations
- **Async/await**: Use async handlers for I/O operations

## Key Architectural Patterns

### Offline-First (Frontend)

1. **Local cache** (Drift sqlite3) mirrors Drive folder structure
2. **Offline queue** stores pending operations
3. **Auto-sync** when connection restored
4. **Conflict resolution**: Last-write-wins with history

### Minimal Backend Responsibilities

Backend only handles:
- Background indexing (RAG)
- OCR processing
- AI queries
- Metadata management in Supabase

Frontend handles:
- Direct Google Drive operations
- Local caching and offline support
- UI and user interactions

### Security Layers

1. **Google OAuth**: User authentication and Drive access
2. **Encrypted storage**: Tokens and API keys encrypted in Supabase
3. **Row Level Security**: Supabase RLS policies
4. **HTTPS only**: All communication encrypted
5. **Audit logs**: Track sensitive operations

## File Naming Conventions

### Frontend (Dart)
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/functions: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`

### Backend (Python)
- Files: `snake_case.py`
- Classes: `PascalCase`
- Functions/variables: `snake_case`
- Constants: `SCREAMING_SNAKE_CASE`

## Configuration Files

- `.env` files: Environment-specific configuration (never commit)
- `*.template` files: Templates for `.env` files (commit these)
- `.gitignore`: Excludes `.env`, build artifacts, dependencies
- `pyproject.toml`: Python dependencies and project metadata
- `pubspec.yaml`: Flutter dependencies and assets

## Development Workflow

1. **Feature branches**: Create from main for new features
2. **Spec-driven**: Refer to `.kiro/specs/scholarmate/` for requirements
3. **Incremental**: Follow 18-phase development plan in tasks.md
4. **Test locally**: Use provided batch scripts or commands
5. **Document**: Update relevant README files for significant changes
