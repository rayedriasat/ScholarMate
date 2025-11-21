# Analytics & Insights Feature

## Overview

Track reading time and pages read with offline-first analytics that sync to the backend.

## Features

- **Reading Sessions**: Automatic tracking when viewing PDFs
- **Page Tracking**: Records which pages have been read and how many times
- **Statistics**:
  - Total reading time
  - Total pages read
  - Reading streak (consecutive days)
  - Most read files
  - 30-day activity heatmap
- **Offline-First**: All tracking works offline, syncs when online

## Usage

### Access Analytics

1. Open the app
2. Tap the menu (⋮) in the top-right
3. Select "Analytics & Insights"

### What's Tracked

- **Automatic**: Reading sessions start when you open a PDF
- **Page reads**: Tracked as you navigate through pages
- **Duration**: Time spent reading each file
- **Activity**: Daily reading activity for streak calculation

## Implementation

### Frontend

**Database Tables** (`frontend/lib/database/tables.dart`):
- `ReadingSessions`: Tracks reading sessions with duration and pages
- `PageReadHistory`: Tracks individual page reads

**Service** (`frontend/lib/services/analytics_service.dart`):
- `startSession()`: Begin tracking a reading session
- `updateCurrentPage()`: Track page navigation
- `endSession()`: End session and calculate duration
- `syncToBackend()`: Sync unsynced data to server
- `getTotalReadingTime()`: Get aggregate stats
- `getReadingStreak()`: Calculate consecutive reading days

**Screen** (`frontend/lib/screens/analytics_screen.dart`):
- Summary cards (time, pages, streak, files)
- 30-day activity heatmap
- Top 5 most read files

### Backend

**Migration** (`backend/migrations/007_analytics.sql`):
- Creates `reading_sessions` table
- Creates `page_read_history` table
- Adds indexes for performance

**API** (`backend/app/routers/analytics.py`):
- `POST /api/analytics/sync`: Sync analytics from client
- `GET /api/analytics/sessions`: Get reading sessions
- `GET /api/analytics/stats`: Get aggregated statistics

**Models** (`backend/app/models/analytics.py`):
- Request/response models for analytics data

## Setup

### 1. Apply Migration

```bash
cd backend
uv run python apply_analytics_migration.py
```

### 2. Verify Tables

Check Supabase dashboard for:
- `reading_sessions` table
- `page_read_history` table

### 3. Test

1. Open a PDF in the app
2. Navigate through pages
3. Close the PDF
4. Open Analytics & Insights
5. Verify stats are displayed

## Architecture

### Offline-First Flow

1. **PDF Opens**: `startSession()` creates local session
2. **Page Navigation**: `updateCurrentPage()` tracks pages locally
3. **PDF Closes**: `endSession()` calculates duration
4. **Background Sync**: `syncToBackend()` uploads unsynced data
5. **Server Storage**: Backend stores in Supabase

### Data Flow

```
PDF Viewer → AnalyticsService → Drift DB → Sync → Backend API → Supabase
```

### Sync Strategy

- Mark records with `isSynced` flag
- Sync unsynced records on connection
- Upsert to handle duplicates
- Continue on sync failure (retry later)

## Privacy

- All data is user-scoped (filtered by `user_id`)
- No cross-user data access
- Stored in user's Supabase account
- Can be cleared by deleting local database

## Future Enhancements

- Export analytics data
- Weekly/monthly reports
- Reading goals and achievements
- File-specific analytics view
- Comparison with previous periods
- Reading speed calculation
