# Task 14: Next Steps - Generate Database Code

## Step 1: Generate Drift Database Code

The Drift database schema has been updated with Tags and FileTags tables. You need to regenerate the database code.

### Run this command:

```bash
cd frontend
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate `frontend/lib/database/database.g.dart` with the new table definitions.

## Step 2: Apply Supabase Migration

1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy and paste the contents of `backend/supabase_migrations/004_tags.sql`
4. Execute the SQL

This will create:
- `tags` table
- `file_tags` table
- Indexes for performance
- Row Level Security policies
- Triggers for automatic timestamps

## Step 3: Test Backend API

Start the backend server:
```bash
cd backend
uv run python run.py
```

Visit http://localhost:8000/docs to see the new tag endpoints in Swagger UI.

## Step 4: Verify Frontend Compilation

After generating the database code, verify the frontend compiles:
```bash
cd frontend
flutter run -d chrome
```

## What's Been Implemented

### Backend ✅
- Tag service with full CRUD operations
- File-tag relationship management
- Bulk tagging support
- Document count tracking
- Supabase integration with RLS

### Frontend ✅
- Drift tables for local caching
- Tag and FileTag models
- TagService with offline-first architecture
- ApiService methods for backend communication
- Auto-sync when online

### Still TODO (UI Components)
- Tag management screen
- Tag creation/edit dialogs
- File tagging UI
- Tag filter panel
- Tag chips on file cards
- Bulk tagging interface
- Tag statistics view
- Realtime sync subscriptions

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter Frontend                      │
├─────────────────────────────────────────────────────────┤
│  UI Layer                                                │
│  ├─ Tag Management Screen (TODO)                        │
│  ├─ Tag Selection Dialog (TODO)                         │
│  └─ Tag Filter Panel (TODO)                             │
├─────────────────────────────────────────────────────────┤
│  Service Layer                                           │
│  ├─ TagService (✅ Implemented)                         │
│  │   ├─ Offline-first with Drift cache                  │
│  │   ├─ Auto-sync with backend                          │
│  │   └─ ChangeNotifier for UI updates                   │
│  └─ ApiService (✅ Tag methods added)                   │
├─────────────────────────────────────────────────────────┤
│  Data Layer                                              │
│  ├─ Drift Database (✅ Tables added)                    │
│  │   ├─ Tags table                                      │
│  │   └─ FileTags table                                  │
│  └─ Models (✅ Tag, FileTag)                            │
└─────────────────────────────────────────────────────────┘
                          ↕ HTTP
┌─────────────────────────────────────────────────────────┐
│                   FastAPI Backend                        │
├─────────────────────────────────────────────────────────┤
│  Router Layer (✅ /api/tags/*)                          │
│  ├─ GET /api/tags                                        │
│  ├─ POST /api/tags                                       │
│  ├─ PUT /api/tags/{id}                                   │
│  ├─ DELETE /api/tags/{id}                                │
│  ├─ GET /api/tags/file/{file_id}                         │
│  ├─ POST /api/tags/file                                  │
│  ├─ DELETE /api/tags/file/{file_id}/{tag_id}             │
│  └─ POST /api/tags/bulk                                  │
├─────────────────────────────────────────────────────────┤
│  Service Layer (✅ TagService)                           │
│  ├─ CRUD operations                                      │
│  ├─ File-tag relationships                               │
│  ├─ Bulk operations                                      │
│  └─ Document counting                                    │
└─────────────────────────────────────────────────────────┘
                          ↕ SQL
┌─────────────────────────────────────────────────────────┐
│                  Supabase PostgreSQL                     │
├─────────────────────────────────────────────────────────┤
│  Tables (✅ Migration ready)                             │
│  ├─ tags (id, user_id, name, color, timestamps)         │
│  └─ file_tags (id, user_id, file_id, tag_id)            │
├─────────────────────────────────────────────────────────┤
│  Security (✅ RLS policies)                              │
│  ├─ Users can only access their own tags                │
│  └─ Users can only access their own file_tags           │
├─────────────────────────────────────────────────────────┤
│  Performance (✅ Indexes)                                │
│  ├─ idx_tags_user_id                                     │
│  ├─ idx_tags_name                                        │
│  ├─ idx_file_tags_user_id                                │
│  ├─ idx_file_tags_file_id                                │
│  └─ idx_file_tags_tag_id                                 │
└─────────────────────────────────────────────────────────┘
```

## Offline-First Flow

1. **User creates tag offline**
   - Saved to local Drift database with `isSynced = false`
   - UI updates immediately (optimistic update)
   - When online, syncs to Supabase backend
   - `isSynced` flag updated to `true`

2. **User tags a file offline**
   - File-tag relationship saved locally
   - UI shows tag chip immediately
   - Syncs to backend when online

3. **User comes online**
   - TagService checks connectivity
   - Fetches latest tags from backend
   - Merges with local cache
   - Pushes unsynced changes

4. **Conflict resolution**
   - Last-write-wins based on `updated_at` timestamp
   - Server version takes precedence in conflicts

## Error Handling

- **Network errors**: Operations continue offline, queued for sync
- **Duplicate tag names**: Backend validates and returns 409 Conflict
- **Missing tags**: Backend returns 404 Not Found
- **Permission errors**: RLS policies enforce data isolation

## Performance Considerations

- **Indexes**: All foreign keys and frequently queried columns indexed
- **Batch operations**: Bulk tagging uses single API call
- **Lazy loading**: Document counts calculated on-demand
- **Caching**: Local Drift cache reduces backend calls

## Security

- **RLS Policies**: Supabase enforces user isolation at database level
- **User ID validation**: All endpoints require user_id parameter
- **Cascade deletes**: Deleting tag removes all file associations
- **Input validation**: Pydantic models validate all inputs

## Next Development Session

Focus on UI implementation:
1. Create tag management screen
2. Add tag selection dialog
3. Display tag chips on file cards
4. Implement tag filtering
5. Add sorting options
6. Create tag statistics view
7. Set up Realtime subscriptions

See `TASK_14_TAG_SYSTEM_IMPLEMENTATION.md` for detailed implementation notes.
