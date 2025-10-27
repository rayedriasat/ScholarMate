# Annotation Synchronization - Usage Guide

## Overview
The annotation synchronization feature allows users to create, update, and delete PDF annotations that automatically sync across devices. Annotations work offline and sync when connectivity is restored.

## Features

### Online Mode
- **Immediate Sync**: Annotations created online are instantly synced to the backend
- **Real-time Updates**: Changes are immediately reflected in the database
- **Conflict Resolution**: Last-write-wins strategy handles concurrent edits

### Offline Mode
- **Local Storage**: Annotations saved locally in Drift database
- **Sync Queue**: Offline annotations queued for sync
- **Auto-Sync**: Automatic sync when connectivity restored

### Sync Status
- **Visual Indicators**: Color-coded status (blue=syncing, green=synced, red=error)
- **Timestamps**: Shows when last sync occurred
- **Retry Option**: Manual retry for failed syncs

## Usage

### For Developers

#### 1. Setup Services

```dart
// Initialize services
final database = AppDatabase();
final authService = AuthService();
final connectivityService = ConnectivityService();

final annotationSyncService = AnnotationSyncService(
  database: database,
  authService: authService,
  baseUrl: 'http://localhost:8000',
);

final annotationService = AnnotationService(
  database: database,
  cacheService: cacheService,
  syncService: annotationSyncService,
  connectivityService: connectivityService,
);
```

#### 2. Create Annotation

```dart
// Create annotation (auto-detects online/offline)
final annotation = await annotationService.createAnnotation(
  fileId: 'file-uuid',
  pageNumber: 1,
  type: AnnotationType.highlight,
  boundingBox: Rect.fromLTRB(100, 200, 300, 250),
  color: Colors.yellow,
  content: 'Important text',
  authorId: currentUser.id,
  authorName: currentUser.displayName,
);
```

#### 3. Fetch Latest Annotations

```dart
// Fetch latest annotations on file open
await annotationService.fetchLatestAnnotations(fileId);
```

#### 4. Sync Offline Annotations

```dart
// Manually trigger sync
final result = await annotationSyncService.syncOfflineAnnotations(fileId);
print('Synced: ${result['synced_count']}');
print('Failed: ${result['failed_count']}');
print('Conflicts: ${result['conflicts'].length}');
```

#### 5. Display Sync Status

```dart
// Add sync indicator to UI
AnnotationSyncIndicator(fileId: fileId)

// Add sync badge to annotation list
AnnotationSyncBadge(isSynced: annotation.isSynced)
```

### For Backend API

#### Create Annotation
```bash
curl -X POST "http://localhost:8000/api/annotations/?user_id=USER_UUID" \
  -H "Content-Type: application/json" \
  -d '{
    "file_id": "FILE_UUID",
    "annotation_type": "highlight",
    "page_number": 1,
    "position_data": {
      "left": 100.0,
      "top": 200.0,
      "right": 300.0,
      "bottom": 250.0
    },
    "content": "Selected text",
    "color": "#FFFF00"
  }'
```

#### Get Annotations
```bash
curl "http://localhost:8000/api/annotations/FILE_UUID?user_id=USER_UUID"
```

#### Bulk Sync
```bash
curl -X POST "http://localhost:8000/api/annotations/sync?user_id=USER_UUID&file_id=FILE_UUID" \
  -H "Content-Type: application/json" \
  -d '{
    "annotations": [
      {
        "file_id": "FILE_UUID",
        "annotation_type": "highlight",
        "page_number": 1,
        "position_data": {...},
        "content": "Text",
        "color": "#FFFF00"
      }
    ]
  }'
```

#### Update Annotation
```bash
curl -X PUT "http://localhost:8000/api/annotations/ANNOTATION_UUID?user_id=USER_UUID" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "Updated text",
    "color": "#FF0000"
  }'
```

#### Delete Annotation
```bash
curl -X DELETE "http://localhost:8000/api/annotations/ANNOTATION_UUID?user_id=USER_UUID"
```

## Conflict Resolution

### How It Works
1. Client sends annotation with `updated_at` timestamp
2. Server compares with existing annotation timestamp
3. If client is newer: Server updates with client data
4. If server is newer: Server keeps its data, reports conflict
5. Client receives conflict information for user review

### Conflict Response
```json
{
  "success": true,
  "synced_count": 5,
  "failed_count": 0,
  "conflicts": [
    {
      "annotation_id": "uuid",
      "reason": "server_newer",
      "server_updated_at": "2025-10-28T10:05:00Z",
      "client_updated_at": "2025-10-28T10:00:00Z"
    }
  ],
  "message": "Synced 5 annotations, 0 failed, 1 conflicts"
}
```

## Testing

### Backend Tests
```bash
# Start backend
cd backend
uv run python run.py

# Run tests (in another terminal)
cd backend
uv run python test_annotation_sync.py
```

### Manual Testing

1. **Online Creation**
   - Ensure device is online
   - Create annotation
   - Verify immediate sync (green indicator)

2. **Offline Creation**
   - Disable network
   - Create annotation
   - Verify local storage (orange badge)
   - Enable network
   - Verify auto-sync (green indicator)

3. **Conflict Resolution**
   - Create annotation on Device A
   - Edit same annotation on Device B
   - Sync both devices
   - Verify last-write-wins

4. **Sync Status**
   - Check sync indicator colors
   - Verify timestamp updates
   - Test retry button on errors

## Troubleshooting

### Annotations Not Syncing
1. Check network connectivity
2. Verify backend is running
3. Check authentication status
4. Review error logs

### Sync Errors
1. Click retry button in UI
2. Check backend logs for errors
3. Verify user permissions
4. Ensure file exists in database

### Conflicts Not Resolving
1. Verify timestamps are correct
2. Check conflict resolution logic
3. Review server logs
4. Ensure database triggers are working

## Best Practices

### For Users
- Work online when possible for immediate sync
- Check sync status before closing app
- Retry failed syncs before making new edits

### For Developers
- Always check connectivity before sync operations
- Handle sync errors gracefully
- Provide clear feedback to users
- Test offline scenarios thoroughly
- Monitor sync performance

## Performance Tips

1. **Batch Operations**: Use bulk sync for multiple annotations
2. **Incremental Sync**: Only sync unsynced annotations
3. **Local Cache**: Minimize network requests
4. **Background Sync**: Sync in background when possible
5. **Efficient Queries**: Use database indexes

## Security Considerations

1. **Authentication**: All endpoints require user_id
2. **Authorization**: Users can only access their own annotations
3. **Validation**: Input validation on all endpoints
4. **Encryption**: HTTPS for all API calls
5. **RLS Policies**: Row-level security in Supabase

## Future Enhancements

- Real-time collaboration via Supabase Realtime
- Manual conflict resolution UI
- Annotation version history viewer
- Batch conflict resolution
- Export/import annotations
- Annotation templates
- Advanced filtering and search

## Support

For issues or questions:
1. Check this documentation
2. Review backend logs
3. Check frontend console
4. Run test scripts
5. Review database state

## Related Documentation

- [Task 9 Complete](TASK_9_COMPLETE.md) - Implementation details
- [Database Schema](backend/migrations/001_initial_schema.sql) - Database structure
- [API Documentation](http://localhost:8000/docs) - Swagger UI (when backend running)
