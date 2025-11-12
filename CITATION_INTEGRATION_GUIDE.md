# Citation & Metadata Feature - Integration Guide

## Quick Start

### 1. Backend Setup (Already Complete)

The backend is ready to use. No additional dependencies needed.

**Test the API**:
```bash
# Start backend
cd backend
uv run python run.py

# Test health endpoint
curl http://localhost:8000/api/health

# View API docs
# Open: http://localhost:8000/docs
```

### 2. Frontend Integration

#### Step 1: Add MetadataService to Provider

Edit `frontend/lib/main.dart`:

```dart
import 'services/metadata_service.dart';

// In your Provider setup:
MultiProvider(
  providers: [
    // ... existing providers (AuthService, DriveService, etc.)
    
    // Add MetadataService
    ProxyProvider<AuthService, MetadataService>(
      update: (context, authService, previous) => MetadataService(
        baseUrl: const String.fromEnvironment('BACKEND_URL', 
          defaultValue: 'http://localhost:8000'),
        getToken: () => authService.idToken ?? '',
      ),
    ),
  ],
  child: MyApp(),
)
```

#### Step 2: Add Metadata Button to PDF Viewer

Edit `frontend/lib/screens/pdf_viewer_screen.dart`:

```dart
import '../widgets/file_metadata_sidebar.dart';
import '../services/metadata_service.dart';
import 'package:provider/provider.dart';

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  bool _showMetadataSidebar = false;
  
  @override
  Widget build(BuildContext context) {
    final metadataService = Provider.of<MetadataService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
        actions: [
          // ... existing actions
          
          // Add metadata button
          IconButton(
            icon: Icon(_showMetadataSidebar ? Icons.info : Icons.info_outline),
            onPressed: () {
              setState(() {
                _showMetadataSidebar = !_showMetadataSidebar;
              });
            },
            tooltip: 'File Metadata',
          ),
        ],
      ),
      body: Row(
        children: [
          // PDF viewer
          Expanded(
            child: /* your existing PDF viewer */,
          ),
          
          // Metadata sidebar
          if (_showMetadataSidebar)
            FileMetadataSidebar(
              file: widget.file,
              metadataService: metadataService,
              onClose: () {
                setState(() {
                  _showMetadataSidebar = false;
                });
              },
            ),
        ],
      ),
    );
  }
}
```

#### Step 3: Add Citation Generator to Navigation

Edit your main navigation (e.g., `frontend/lib/widgets/app_navigation.dart` or drawer):

```dart
import '../screens/citation_generator_screen.dart';
import '../services/metadata_service.dart';
import 'package:provider/provider.dart';

// In your navigation menu/drawer:
ListTile(
  leading: const Icon(Icons.format_quote),
  title: const Text('Citation Generator'),
  onTap: () {
    Navigator.pop(context); // Close drawer if applicable
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CitationGeneratorScreen(
          metadataService: Provider.of<MetadataService>(context, listen: false),
        ),
      ),
    );
  },
),
```

#### Step 4: Add to Home Screen (Optional)

Add a quick access button on the home screen:

```dart
// In home_screen.dart
Card(
  child: InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CitationGeneratorScreen(
            metadataService: Provider.of<MetadataService>(context, listen: false),
          ),
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.format_quote, size: 48),
          const SizedBox(height: 8),
          const Text('Citation Generator'),
        ],
      ),
    ),
  ),
)
```

## Testing

### Test Backend Endpoints

```bash
# 1. Get auth token (use your existing auth flow)
TOKEN="your_jwt_token_here"

# 2. Test metadata extraction
curl -X POST http://localhost:8000/api/metadata/extract \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "file_id": "your_google_drive_file_id",
    "file_name": "paper.pdf",
    "extract_from_content": true
  }'

# 3. Test citation generation (DOI)
curl -X POST http://localhost:8000/api/metadata/citation/generate \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "identifier_type": "doi",
    "identifier_value": "10.1038/nature12345"
  }'

# 4. Test citation generation (arXiv)
curl -X POST http://localhost:8000/api/metadata/citation/generate \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "identifier_type": "arxiv",
    "identifier_value": "2301.12345"
  }'
```

### Test Frontend

1. **Test Metadata Sidebar**:
   - Open a PDF file
   - Click the metadata button (info icon)
   - Verify sidebar opens with metadata
   - Test copy buttons
   - Test close button

2. **Test Citation Generator**:
   - Navigate to Citation Generator
   - Select "DOI" from dropdown
   - Enter: `10.1038/nature12345`
   - Click "Generate Citations"
   - Verify all citation formats appear
   - Test copy buttons for each format

## Common Issues & Solutions

### Issue 1: MetadataService not found

**Error**: `Provider.of<MetadataService>() called with a context that does not contain a MetadataService`

**Solution**: Ensure MetadataService is added to your Provider setup in `main.dart`

### Issue 2: CORS errors

**Error**: `Access to XMLHttpRequest blocked by CORS policy`

**Solution**: Ensure backend CORS is configured correctly in `backend/app/main.py`:
```python
cors_origins = [
    "http://localhost:8080",  # Flutter web dev server
    "http://localhost:3000",
    # Add your frontend URLs
]
```

### Issue 3: 401 Unauthorized

**Error**: API returns 401 status

**Solution**: 
- Verify user is logged in
- Check token is being passed correctly
- Ensure `getToken` function returns valid JWT

### Issue 4: External API timeout

**Error**: Citation generation times out

**Solution**:
- Check internet connection
- Verify external APIs are accessible
- Try a different identifier
- Check backend logs for specific error

## API Examples

### Example 1: Extract Metadata from PDF

```dart
final metadata = await metadataService.extractMetadata(
  fileId: 'google_drive_file_id',
  fileName: 'research_paper.pdf',
  extractFromContent: true,
);

if (metadata != null) {
  print('Title: ${metadata.title}');
  print('Authors: ${metadata.authors.join(", ")}');
  print('Year: ${metadata.publicationYear}');
  print('DOI: ${metadata.doi}');
}
```

### Example 2: Generate Citation from DOI

```dart
final citation = await metadataService.generateCitation(
  identifierType: 'doi',
  identifierValue: '10.1038/nature12345',
);

if (citation != null) {
  print('APA: ${citation.apa}');
  print('MLA: ${citation.mla}');
  print('Chicago: ${citation.chicago}');
  print('BibTeX: ${citation.bibtex}');
}
```

### Example 3: Generate Citation from Metadata

```dart
final metadata = PDFMetadata(
  title: 'Example Paper',
  authors: ['John Doe', 'Jane Smith'],
  publicationYear: 2023,
  journal: 'Nature',
  doi: '10.1234/example',
);

final citation = await metadataService.generateCitationFromMetadata(metadata);
```

## Deployment Checklist

- [ ] Backend deployed with metadata endpoints
- [ ] Frontend includes MetadataService in Provider
- [ ] PDF viewer has metadata button
- [ ] Citation Generator accessible from navigation
- [ ] Test all identifier types (DOI, arXiv, ISBN, PMID, URL)
- [ ] Test offline behavior (metadata extraction should work)
- [ ] Test error handling (invalid identifiers, network errors)
- [ ] Verify copy-to-clipboard functionality
- [ ] Check mobile responsiveness
- [ ] Test with various PDF files

## Performance Tips

1. **Cache Metadata**: Store extracted metadata in Drift database to avoid re-extraction
2. **Debounce Requests**: Add debouncing to citation generator input
3. **Loading States**: Show clear loading indicators during API calls
4. **Error Recovery**: Provide retry buttons for failed requests
5. **Offline Queue**: Queue citation requests when offline, process when online

## Next Steps

1. Test the features thoroughly
2. Gather user feedback
3. Consider adding:
   - Batch citation generation
   - Citation history
   - Custom citation styles
   - Metadata editing
   - Export to .bib files

## Support

For issues or questions:
1. Check backend logs: `backend/logs/`
2. Check browser console for frontend errors
3. Verify API endpoints in Swagger: `http://localhost:8000/docs`
4. Review `CITATION_METADATA_FEATURE.md` for detailed documentation
