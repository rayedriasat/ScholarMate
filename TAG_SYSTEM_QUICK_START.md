# Tag System - Quick Start Guide

## 🚀 Getting Started

### Setup (One-Time)

#### Backend
```bash
# 1. Apply Supabase migration
# Open Supabase SQL Editor and execute:
# backend/supabase_migrations/004_tags.sql

# 2. Start backend
cd backend
uv run python run.py
```

#### Frontend
```bash
# 1. Install dependencies
cd frontend
flutter pub get

# 2. Generate Drift database
flutter pub run build_runner build --delete-conflicting-outputs

# 3. Run app
flutter run -d chrome
```

---

## 📖 User Guide

### Creating Tags

1. Open file explorer
2. Click **⋮** (menu) → **Manage Tags**
3. Click **+** button
4. Enter tag name
5. Choose color
6. Click **Create**

### Tagging Files

#### Single File
1. Right-click file
2. Select **Manage Tags**
3. Check tags to apply
4. Click **Save**

#### Multiple Files
1. Long-press to select first file
2. Tap other files to select
3. Click **🏷️** (tag button) in toolbar
4. Select tags
5. Click **Save**

### Filtering by Tags

1. Click **🔍** (filter icon) in toolbar
2. Tag panel appears on right
3. Check tags to filter by
4. Toggle **ANY** / **ALL** mode:
   - **ANY**: Show files with any selected tag
   - **ALL**: Show files with all selected tags
5. Click **Clear** to remove filters

### Sorting Files

1. Click **⇅** (sort icon) in toolbar
2. Select sort option:
   - **Name**: Alphabetical
   - **Date**: Modified time
   - **Size**: File size
   - **Tag**: By tags (experimental)
3. Click again to reverse order

### Managing Tags

1. Open **⋮** menu → **Manage Tags**
2. View all tags with document counts
3. Click tag to edit:
   - Rename
   - Change color
4. Click **🗑️** to delete (with confirmation)

---

## 💻 Developer Guide

### Backend API

#### List Tags
```http
GET /api/tags
Authorization: Bearer {token}
```

#### Create Tag
```http
POST /api/tags
Content-Type: application/json

{
  "name": "Research",
  "color": "#2196F3"
}
```

#### Update Tag
```http
PUT /api/tags/{tag_id}
Content-Type: application/json

{
  "name": "Updated Name",
  "color": "#FF5722"
}
```

#### Delete Tag
```http
DELETE /api/tags/{tag_id}
```

#### Get File Tags
```http
GET /api/tags/file/{file_id}
```

#### Add Tag to File
```http
POST /api/tags/file
Content-Type: application/json

{
  "file_id": "abc123",
  "tag_id": "def456"
}
```

#### Bulk Tag Files
```http
POST /api/tags/bulk
Content-Type: application/json

{
  "file_ids": ["file1", "file2"],
  "tag_ids": ["tag1", "tag2"]
}
```

### Frontend Service

```dart
import 'package:provider/provider.dart';
import '../services/tag_service.dart';

// Get service
final tagService = context.read<TagService>();

// Create tag
final tag = await tagService.createTag(
  userId: userId,
  name: 'Research',
  color: '#2196F3',
);

// Get all tags
final tags = await tagService.getTags(userId);

// Tag a file
await tagService.addTagToFile(
  userId: userId,
  fileId: fileId,
  tagId: tagId,
);

// Get file tags
final fileTags = await tagService.getTagsForFile(fileId);

// Bulk tag
await tagService.bulkTagFiles(
  userId: userId,
  fileIds: ['file1', 'file2'],
  tagIds: ['tag1', 'tag2'],
);
```

### Database Queries

```dart
import '../database/database.dart';

final db = AppDatabase();

// Get files by tags (ANY)
final files = await db.getFilesByTags(
  ['tag1', 'tag2'],
  matchAll: false,
);

// Get files by tags (ALL)
final files = await db.getFilesByTags(
  ['tag1', 'tag2'],
  matchAll: true,
);

// Get tag with document count
final tags = await db.getTagsWithCounts(userId);
```

---

## 🎨 UI Components

### TagChip
Display a single tag:
```dart
TagChip(
  tag: tag,
  small: true,
  onTap: () => print('Tapped'),
  onDelete: () => print('Deleted'),
)
```

### TagChipList
Display multiple tags:
```dart
TagChipList(
  tags: tags,
  small: true,
  maxTags: 3,
  onTagTap: (tag) => print('Tapped $tag'),
  onTagDelete: (tag) => print('Deleted $tag'),
)
```

### TagSelectionDialog
Multi-select dialog:
```dart
final result = await showDialog<bool>(
  context: context,
  builder: (context) => TagSelectionDialog(
    fileIds: ['file1', 'file2'],
    currentTags: existingTags,
  ),
);
```

### TagFilterPanel
Filter sidebar:
```dart
TagFilterPanel(
  selectedTagIds: selectedTagIds,
  filterMode: TagFilterMode.any,
  onFilterChanged: (tagIds, mode) {
    setState(() {
      selectedTagIds = tagIds;
      filterMode = mode;
    });
  },
)
```

---

## 🔧 Troubleshooting

### Tags not syncing
1. Check internet connection
2. Verify backend is running
3. Check Supabase migration applied
4. Review console for errors

### Tags not appearing on files
1. Ensure file is not a folder
2. Check tags were saved successfully
3. Refresh file list
4. Verify database has records

### Filter not working
1. Clear filters and try again
2. Check tag IDs are correct
3. Verify files have the selected tags
4. Review filter mode (ANY vs ALL)

### Performance issues
1. Check database indexes exist
2. Limit number of tags per file
3. Use bulk operations for multiple files
4. Review network requests

---

## 📊 Best Practices

### Tag Naming
- ✅ Use clear, descriptive names
- ✅ Keep names short (under 20 chars)
- ✅ Use consistent naming convention
- ❌ Avoid special characters
- ❌ Don't duplicate tag names

### Tag Colors
- ✅ Use distinct colors for different categories
- ✅ Group related tags with similar colors
- ✅ Consider color-blind users
- ❌ Don't use too many similar colors

### Tag Organization
- ✅ Create tags before bulk tagging
- ✅ Use 3-5 tags per file maximum
- ✅ Review and clean up unused tags
- ✅ Use descriptive tag names
- ❌ Don't create too many tags

### Performance
- ✅ Use bulk operations for multiple files
- ✅ Filter by 1-3 tags at a time
- ✅ Keep tag names short
- ✅ Delete unused tags
- ❌ Don't tag every file with every tag

---

## 🎯 Common Use Cases

### Research Papers
```
Tags: Research, AI, Machine Learning, 2024
Filter: ANY (Research, AI)
Sort: Date (newest first)
```

### Course Materials
```
Tags: CS101, Lecture, Assignment, Exam
Filter: ALL (CS101, Lecture)
Sort: Name (alphabetical)
```

### Project Documents
```
Tags: Project-X, Draft, Final, Review
Filter: ANY (Project-X)
Sort: Date (newest first)
```

### Personal Notes
```
Tags: Personal, Ideas, Todo, Archive
Filter: ANY (Personal, Ideas)
Sort: Date (newest first)
```

---

## 📚 Additional Resources

- **API Documentation**: http://localhost:8000/docs
- **Implementation Details**: TASK_14_TAG_SYSTEM_IMPLEMENTATION.md
- **Verification Guide**: TASK_14_VERIFICATION.md
- **Complete Status**: TASK_14_COMPLETE.md

---

## 🆘 Support

If you need help:
1. Check this guide first
2. Review error messages in console
3. Check backend logs
4. Verify Supabase configuration
5. Review implementation files

---

**Last Updated**: October 31, 2025  
**Version**: 1.0.0  
**Status**: Production-Ready
