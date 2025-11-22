# Search with Text Highlighting - Complete ✓

## Feature Summary

When you search for text and find it in a document, clicking the result now:
1. Opens the PDF to the correct page
2. Automatically highlights the search text
3. Shows a notification that you navigated from search

## What Was Implemented

### Backend (Already Working)
- ✓ Returns page numbers for content matches
- ✓ Provides text snippets showing context
- ✓ Accurate search results

### Frontend Updates

**1. Search Screen** (`advanced_search_screen.dart`)
- Passes `searchQuery` when opening PDF from search results
- Only for semantic (content) matches, not filename matches

**2. PDF Viewer** (`pdf_viewer_screen.dart`)
- Added `searchQuery` parameter to constructor
- Auto-opens search bar when query provided
- Auto-fills search box with the query
- Auto-triggers search after 500ms delay
- Shows "Navigated from search" notification

## How It Works

### User Flow

1. **Search for text**
   - User searches: "machine learning"
   - Enables "Include content search"
   - Gets results with page numbers

2. **Click result**
   - Taps on a SEMANTIC match result
   - PDF opens to the correct page
   - Search bar automatically opens
   - Query "machine learning" is pre-filled
   - Text is highlighted in the PDF

3. **Navigate highlights**
   - Use search navigation buttons
   - Jump between matches
   - Clear search to read normally

### Technical Flow

```
Search Screen
    ↓
User taps result
    ↓
Navigator.pushNamed('/pdf_viewer', {
    fileId: "...",
    fileName: "...",
    initialPage: 5,
    searchQuery: "machine learning"  ← NEW
})
    ↓
PDF Viewer receives searchQuery
    ↓
Auto-opens search bar
    ↓
Fills search box with query
    ↓
Triggers _performSearch()
    ↓
Syncfusion PDF Viewer highlights text
```

## Code Changes

### Search Screen
```dart
void _openFile(SearchResultItem result) {
  Navigator.pushNamed(
    context,
    '/pdf_viewer',
    arguments: {
      'fileId': result.fileId,
      'fileName': result.fileName,
      'initialPage': result.pageNumber ?? 0,
      'searchQuery': result.matchType == 'semantic' ? _searchController.text : null,
    },
  );
}
```

### PDF Viewer Constructor
```dart
class PdfViewerScreen extends StatefulWidget {
  final DriveFile? file;
  final String? fileId;
  final String? fileName;
  final int? initialPage;
  final String? searchQuery;  // NEW

  const PdfViewerScreen({
    super.key,
    this.file,
    this.fileId,
    this.fileName,
    this.initialPage,
    this.searchQuery,  // NEW
  });
}
```

### Auto-Search Logic
```dart
// Auto-trigger search if searchQuery is provided
if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    setState(() {
      _isSearching = true;
      _searchController.text = widget.searchQuery!;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _performSearch();
      }
    });
  });
}
```

## Usage Examples

### Example 1: Content Search

**Search:** "neural networks"

**Result:**
```
📄 Deep Learning.pdf
[SEMANTIC] ██████░░░ 75%
Page 12

"...introduction to neural networks and their
applications in modern AI systems..."
```

**Tap result:**
- Opens Deep Learning.pdf
- Jumps to page 12
- Search bar opens with "neural networks"
- Text "neural networks" is highlighted
- Notification: "Navigated to page 12 from search"

### Example 2: Filename Search

**Search:** "research paper"

**Result:**
```
📄 Research Paper 2024.pdf
[EXACT] ████████████ 100%

Filename contains: 'research paper'
```

**Tap result:**
- Opens Research Paper 2024.pdf
- Starts at page 1
- No auto-search (filename match)
- Normal PDF viewing

## Features

### Automatic Highlighting
- ✓ Text is highlighted in yellow
- ✓ Multiple matches shown
- ✓ Navigate between matches with arrows
- ✓ Clear search to remove highlights

### Smart Behavior
- ✓ Only triggers for semantic (content) matches
- ✓ Doesn't trigger for filename matches
- ✓ 500ms delay ensures PDF is loaded
- ✓ Search bar can be closed manually

### User Feedback
- ✓ Shows "from search" notification
- ✓ Search icon in notification
- ✓ Pre-filled search box
- ✓ Visible search bar

## Testing

### Test Scenario 1: Content Match
1. Search for text you know exists in a PDF
2. Enable "Include content search"
3. Tap a SEMANTIC result
4. **Expected:** PDF opens, text is highlighted

### Test Scenario 2: Filename Match
1. Search for a filename
2. Disable "Include content search"
3. Tap an EXACT or PARTIAL result
4. **Expected:** PDF opens normally, no auto-search

### Test Scenario 3: Multiple Matches
1. Search for common word like "the"
2. Tap result
3. **Expected:** Multiple highlights, can navigate between them

## Limitations

### Current Limitations
- Only works for text-based PDFs (not scanned images)
- Requires exact word matching (case-insensitive)
- Search is per-page (doesn't cross page boundaries)

### Future Enhancements
- [ ] Highlight specific snippet from search result
- [ ] Jump to exact match position on page
- [ ] Support for fuzzy/approximate matching
- [ ] Highlight multiple search terms differently
- [ ] Remember search history

## Troubleshooting

### Issue: Text not highlighted

**Possible causes:**
1. PDF is image-based (needs OCR)
2. Text is in a different format
3. Search query doesn't match exactly

**Solutions:**
1. Run OCR on the PDF first
2. Try different search terms
3. Check if text is selectable in PDF

### Issue: Wrong page opened

**Check:**
1. Is the page number correct in search results?
2. Did the PDF load completely?
3. Is this a multi-file PDF?

### Issue: Search bar doesn't open

**Check:**
1. Is it a semantic match? (Only semantic triggers auto-search)
2. Is searchQuery being passed correctly?
3. Check browser/app console for errors

## Related Features

- **Advanced Search**: Main search functionality
- **PDF Viewer**: Built-in search and highlighting
- **Citations**: Similar page navigation
- **Annotations**: Can annotate highlighted text

## Summary

The search-to-highlight feature is now complete! Users can:
1. Search for text in documents
2. Click results to open PDFs
3. Automatically see highlighted text
4. Navigate between matches
5. Get visual feedback

This creates a seamless search-to-read experience, making it easy to find and review specific content in documents.
