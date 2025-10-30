# Task 14: Quick Command Reference

## Essential Commands

### 1. Generate Drift Database Code (REQUIRED)
```bash
cd frontend
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Start Backend Server
```bash
cd backend
uv run python run.py
```

### 3. Run Frontend
```bash
cd frontend
flutter run -d chrome          # Web
flutter run -d windows         # Windows
flutter run                    # Android/iOS
```

### 4. View API Documentation
```
http://localhost:8000/docs     # Swagger UI
http://localhost:8000/redoc    # ReDoc
```

## Development Commands

### Backend

```bash
# Install dependencies
cd backend
uv sync

# Run with auto-reload
uv run python run.py

# Run tests
uv run pytest

# Run specific test
uv run pytest tests/test_tag_service.py

# Check code style
uv run ruff check .

# Format code
uv run ruff format .
```

### Frontend

```bash
# Install dependencies
cd frontend
flutter pub get

# Generate code (Drift, etc.)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate)
flutter pub run build_runner watch

# Run tests
flutter test

# Run specific test
flutter test test/tag_service_test.dart

# Analyze code
flutter analyze

# Format code
dart format .

# Clean build
flutter clean
flutter pub get
```

## Database Commands

### Supabase Migration

1. Open Supabase Dashboard
2. Go to SQL Editor
3. Copy contents of `backend/supabase_migrations/004_tags.sql`
4. Execute

Or use Supabase CLI:
```bash
supabase db push
```

### Check Drift Database

```bash
# View generated database code
cat frontend/lib/database/database.g.dart

# Check schema version
grep "schemaVersion" frontend/lib/database/database.dart
```

## Testing Commands

### Backend API Testing

```bash
# Health check
curl http://localhost:8000/api/health

# Get tags (replace USER_ID)
curl "http://localhost:8000/api/tags?user_id=USER_ID"

# Create tag (replace USER_ID)
curl -X POST "http://localhost:8000/api/tags?user_id=USER_ID" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Tag","color":"#FF0000"}'
```

### Frontend Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Troubleshooting Commands

### Clear Everything and Rebuild

```bash
# Backend
cd backend
rm -rf __pycache__
rm -rf .pytest_cache
uv sync

# Frontend
cd frontend
flutter clean
rm -rf .dart_tool
rm -rf build
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Check Versions

```bash
# Flutter
flutter --version
flutter doctor

# Python
python --version
uv --version

# Node (if needed)
node --version
npm --version
```

### View Logs

```bash
# Backend logs
cd backend
uv run python run.py 2>&1 | tee backend.log

# Frontend logs
cd frontend
flutter run -d chrome --verbose 2>&1 | tee frontend.log
```

## Git Commands

```bash
# Check status
git status

# Add files
git add backend/app/models/tag.py
git add backend/app/services/tag_service.py
git add backend/app/routers/tags.py
git add backend/supabase_migrations/004_tags.sql
git add frontend/lib/models/tag.dart
git add frontend/lib/services/tag_service.dart
git add frontend/lib/screens/tag_management_screen.dart
git add frontend/lib/widgets/tag_*.dart

# Commit
git commit -m "feat: implement tag management system (Task 14)"

# Push
git push origin main
```

## Quick Checks

### Verify Backend is Running
```bash
curl http://localhost:8000/api/health
# Should return: {"status":"healthy","service":"scholarmate-backend"}
```

### Verify Supabase Migration Applied
```sql
-- In Supabase SQL Editor
SELECT * FROM tags LIMIT 1;
SELECT * FROM file_tags LIMIT 1;
```

### Verify Frontend Compiles
```bash
cd frontend
flutter analyze
# Should show no errors
```

### Verify Drift Code Generated
```bash
ls -la frontend/lib/database/database.g.dart
# Should exist and be recent
```

## Environment Setup

### Backend .env
```bash
cd backend
cp .env.template .env
# Edit .env with your values
```

### Frontend .env
```bash
cd frontend
cp .env.template .env
# Edit .env with your values
```

## Package Management

### Add Backend Package
```bash
cd backend
uv add package-name
```

### Add Frontend Package
```bash
cd frontend
flutter pub add package_name
```

## Useful Aliases (Optional)

Add to your `.bashrc` or `.zshrc`:

```bash
# ScholarMate aliases
alias sm-backend='cd ~/scholarmate/backend && uv run python run.py'
alias sm-frontend='cd ~/scholarmate/frontend && flutter run -d chrome'
alias sm-build='cd ~/scholarmate/frontend && flutter pub run build_runner build --delete-conflicting-outputs'
alias sm-test-backend='cd ~/scholarmate/backend && uv run pytest'
alias sm-test-frontend='cd ~/scholarmate/frontend && flutter test'
```

## Quick Reference URLs

- Backend API: http://localhost:8000/docs
- Backend Health: http://localhost:8000/api/health
- Frontend (Web): http://localhost:8080 (or port shown in console)
- Supabase Dashboard: https://app.supabase.com

## Emergency Reset

If everything is broken:

```bash
# Backend
cd backend
rm -rf __pycache__ .pytest_cache
uv sync
uv run python run.py

# Frontend
cd frontend
flutter clean
rm -rf .dart_tool build
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run -d chrome
```

## Next Steps After Setup

1. ✅ Generate Drift code
2. ✅ Apply Supabase migration
3. ✅ Start backend
4. ✅ Run frontend
5. ✅ Test tag creation
6. ✅ Test tag application to files
7. ✅ Test filtering
8. ✅ Test offline mode
9. ✅ Test cross-device sync

## Support

- Documentation: See `README_TASK_14.md`
- Integration: See `TASK_14_INTEGRATION_GUIDE.md`
- Implementation: See `TASK_14_TAG_SYSTEM_IMPLEMENTATION.md`
- API Reference: http://localhost:8000/docs
