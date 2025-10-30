# Task 14: Integration Guide

This guide explains how to integrate the tag management system into your existing ScholarMate file explorer.

## Prerequisites

1. **Generate Drift Database Code**
   ```bash
   cd frontend
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Apply Supabase Migration**
   - Open Supabase SQL Editor
   - Execute `backend/supabase_migrations/004_tags.sql`

3. **Start Backend Server**
   ```bash
   cd backend
   uv run python run.py
   ```

## Integration Steps

### Step 1: Register TagService in Provider

In your `main.dart`, add TagService to the provider tree:

```dart
import 'services/tag_service.dart';

// In your main widget build method:
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthService()),
    ChangeNotifierProvider(create: (_) => ConnectivityService()),
    // ... other providers
    ChangeNotifierProvider(
      create: (context) => TagService(
        database: AppDatabase(),
        apiService: ApiService(),
        connectivityService: context.read<ConnectivityService>(),
      ),
    ),
  ],
  child: MyApp(),
)
```

### Step 2: Add Tag Management to Settings/Menu

Add a navigation item to access the tag management screen:

```dart
import 'screens/tag_management_screen.dart';

// In your settings screen or drawer:
ListTile(
  leading: const Icon(Icons.label),
  title: const Text('Manage Tags'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TagManagementScreen(),
      ),
    );
  },
)
```

### Step 3: Display Tags on File Cards

In your file list/grid item widget, add tag display:

```dart
import 'package:provider/provider.dart';
import 'widgets/tag_chip.dart';
import 'services/tag_service.dart';

class FileCard extends StatefulWidget {
  final String fileId;
  // ... other properties

  @override
  State<FileCard> createState() => _FileCardState();
}

class _FileCardState extends State<FileCard> {
  List<Tag> _tags = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final tagService = context.read<TagService>();
    final tags = await tagService.getTagsForFile(widget.fileId);
    if (mounted) {
      setState(() => _tags = tags);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // ... your existing file card content
          
          // Add tags display
          if (_tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TagChipList(
                tags: _tags,
                small: true,
                maxTags: 3,
                onTagTap: (tag) {
                  // Optional: Filter by this tag
                },
              ),
            ),
        ],
      ),
    );
  }
}
```

### Step 4: Add "Manage Tags" to File Context Menu

In your file context menu (long press or right-click):

```dart
import 'widgets/tag_selection_dialog.dart';

// In your file context menu:
PopupMenuItem(
  child: const Row(
    children: [
      Icon(Icons.label),
      SizedBox(width: 8),
      Text('Manage Tags'),
    ],
  ),
  onTap: () async {
    // Get current tags for the file
    final tagService = context.read<TagService>();
    final currentTags = await tagService.getTagsForFile(fileId);
    
    // Show tag selection dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TagSelectionDialog(
        fileIds: [fileId],
        currentTags: currentTags,
      ),
    );
    
    if (result == true) {
      // Refresh file card to show updated tags
      setState(() {});
    }
  },
)
```

### Step 5: Add Bulk Tagging for Multiple Files

In your file selection mode (when multiple files are selected):

```dart
// Add a toolbar button for bulk tagging
IconButton(
  icon: const Icon(Icons.label),
  tooltip: 'Tag Selected Files',
  onPressed: selectedFileIds.isEmpty ? null : () async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => TagSelectionDialog(
        fileIds: selectedFileIds,
      ),
    );
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tagged ${selectedFileIds.length} files'),
        ),
      );
      // Refresh file list
      setState(() {});
    }
  },
)
```

### Step 6: Add Tag Filter Panel to File Explorer

In your file explorer screen, add the filter panel:

```dart
import 'widgets/tag_filter_panel.dart';

class FileExplorerScreen extends StatefulWidget {
  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  Set<String> _selectedTagIds = {};
  TagFilterMode _filterMode = TagFilterMode.any;
  bool _showTagFilter = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Files'),
        actions: [
          IconButton(
            icon: Icon(_showTagFilter ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() => _showTagFilter = !_showTagFilter);
            },
            tooltip: 'Filter by Tags',
          ),
        ],
      ),
      body: Row(
        children: [
          // Main file list
          Expanded(
            child: _buildFileList(),
          ),
          
          // Tag filter panel (shown when enabled)
          if (_showTagFilter)
            TagFilterPanel(
              selectedTagIds: _selectedTagIds,
              filterMode: _filterMode,
              onFilterChanged: (tagIds, mode) {
                setState(() {
                  _selectedTagIds = tagIds;
                  _filterMode = mode;
                });
                // Refresh file list with filters
                _applyFilters();
              },
            ),
        ],
      ),
    );
  }

  Future<void> _applyFilters() async {
    // Implement your file filtering logic here
    // Query files that have the selected tags based on filter mode
    if (_selectedTagIds.isEmpty) {
      // Show all files
      return;
    }

    // Example: Get files with selected tags
    final tagService = context.read<TagService>();
    // You'll need to implement a method to get files by tags
    // This might involve querying the FileTags table
  }
}
```

### Step 7: Implement File Filtering by Tags

Add a method to your file service or database to filter files by tags:

```dart
// In your database.dart or file service:
Future<List<File>> getFilesByTags(
  Set<String> tagIds,
  TagFilterMode mode,
) async {
  if (tagIds.isEmpty) {
    return getFiles(); // Return all files
  }

  if (mode == TagFilterMode.any) {
    // OR logic: files with ANY of the selected tags
    final fileTagRecords = await (select(fileTags)
          ..where((ft) => ft.tagId.isIn(tagIds.toList())))
        .get();

    final fileIds = fileTagRecords.map((ft) => ft.fileId).toSet();

    return (select(files)
          ..where((f) => f.id.isIn(fileIds.toList())))
        .get();
  } else {
    // AND logic: files with ALL of the selected tags
    final fileIds = <String>{};
    
    for (final tagId in tagIds) {
      final fileTagRecords = await (select(fileTags)
            ..where((ft) => ft.tagId.equals(tagId)))
          .get();

      final tagFileIds = fileTagRecords.map((ft) => ft.fileId).toSet();

      if (fileIds.isEmpty) {
        fileIds.addAll(tagFileIds);
      } else {
        fileIds.retainWhere(tagFileIds.contains);
      }
    }

    return (select(files)
          ..where((f) => f.id.isIn(fileIds.toList())))
        .get();
  }
}
```

### Step 8: Add Sorting Options

Add a sort dropdown to your file explorer:

```dart
enum FileSortOption {
  name,
  date,
  size,
  tag,
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  FileSortOption _sortOption = FileSortOption.name;
  bool _sortAscending = true;

  Widget _buildSortDropdown() {
    return PopupMenuButton<FileSortOption>(
      icon: const Icon(Icons.sort),
      onSelected: (option) {
        setState(() {
          if (_sortOption == option) {
            _sortAscending = !_sortAscending;
          } else {
            _sortOption = option;
            _sortAscending = true;
          }
        });
        _loadFiles();
      },
      itemBuilder: (context) => [
        _buildSortMenuItem(FileSortOption.name, 'Name'),
        _buildSortMenuItem(FileSortOption.date, 'Date'),
        _buildSortMenuItem(FileSortOption.size, 'Size'),
        _buildSortMenuItem(FileSortOption.tag, 'Tag'),
      ],
    );
  }

  PopupMenuItem<FileSortOption> _buildSortMenuItem(
    FileSortOption option,
    String label,
  ) {
    final isSelected = _sortOption == option;
    return PopupMenuItem(
      value: option,
      child: Row(
        children: [
          Icon(
            isSelected
                ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.sort,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
          if (isSelected) const Spacer(),
          if (isSelected) const Icon(Icons.check, size: 20),
        ],
      ),
    );
  }
}
```

## Testing Checklist

After integration, test these scenarios:

- [ ] Create a new tag from tag management screen
- [ ] Edit tag name and color
- [ ] Delete tag (with confirmation)
- [ ] Apply tag to a single file
- [ ] Apply multiple tags to a single file
- [ ] Remove tag from a file
- [ ] Bulk tag multiple files
- [ ] Filter files by single tag
- [ ] Filter files by multiple tags (ANY mode)
- [ ] Filter files by multiple tags (ALL mode)
- [ ] Clear tag filters
- [ ] Sort files by different criteria
- [ ] View tag chips on file cards
- [ ] Offline tag creation (syncs when online)
- [ ] Cross-device sync (create tag on device A, see on device B)

## Troubleshooting

### Tags not showing on file cards
- Ensure `getTagsForFile()` is called in `initState()`
- Check that file IDs match between Drive and local cache
- Verify tags are synced to backend

### Filter not working
- Ensure `_applyFilters()` is called when filter changes
- Check that `getFilesByTags()` query is correct
- Verify FileTags table has correct data

### Sync issues
- Check backend is running (`http://localhost:8000/docs`)
- Verify Supabase migration was applied
- Check network connectivity
- Look for errors in console logs

## Next Steps

1. **Implement Realtime Sync**: Add Supabase Realtime subscriptions for live updates
2. **Add Tag Statistics**: Create a dashboard showing tag usage
3. **Enhance Sorting**: Add more sort options and save preferences
4. **Add Tag Search**: Allow searching/filtering tags by name
5. **Tag Suggestions**: Suggest tags based on file content or name

## API Reference

See `http://localhost:8000/docs` for complete API documentation when backend is running.

Key endpoints:
- `GET /api/tags` - List all tags
- `POST /api/tags` - Create tag
- `PUT /api/tags/{id}` - Update tag
- `DELETE /api/tags/{id}` - Delete tag
- `POST /api/tags/file` - Add tag to file
- `DELETE /api/tags/file/{file_id}/{tag_id}` - Remove tag from file
- `POST /api/tags/bulk` - Bulk tag files
