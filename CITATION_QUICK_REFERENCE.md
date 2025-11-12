# Citation & Metadata - Quick Reference

## 🚀 Quick Start

### Backend (Already Complete)
```bash
cd backend
uv run python run.py
# API docs: http://localhost:8000/docs
```

### Frontend Setup
```dart
// 1. Add to Provider (main.dart)
ProxyProvider<AuthService, MetadataService>(
  update: (_, auth, __) => MetadataService(
    baseUrl: 'http://localhost:8000',
    getToken: () => auth.idToken ?? '',
  ),
)

// 2. Use in widgets
final metadataService = Provider.of<MetadataService>(context);
```

## 📋 API Endpoints

### Extract Metadata
```http
POST /api/metadata/extract
Authorization: Bearer <token>
Content-Type: application/json

{
  "file_id": "drive_file_id",
  "file_name": "paper.pdf",
  "extract_from_content": true
}
```

### Generate Citation
```http
POST /api/metadata/citation/generate
Authorization: Bearer <token>
Content-Type: application/json

{
  "identifier_type": "doi",
  "identifier_value": "10.1234/example"
}
```

## 🎨 UI Components

### File Metadata Sidebar
```dart
FileMetadataSidebar(
  file: driveFile,
  metadataService: metadataService,
  onClose: () => setState(() => showSidebar = false),
)
```

### Citation Generator Screen
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => CitationGeneratorScreen(
      metadataService: metadataService,
    ),
  ),
);
```

## 💻 Code Snippets

### Extract Metadata
```dart
final metadata = await metadataService.extractMetadata(
  fileId: file.id,
  fileName: file.name,
  extractFromContent: true,
);

if (metadata != null) {
  print('Title: ${metadata.title}');
  print('Authors: ${metadata.formattedAuthors}');
  print('DOI: ${metadata.doi}');
}
```

### Generate Citation
```dart
final citation = await metadataService.generateCitation(
  identifierType: 'doi',
  identifierValue: '10.1038/nature12345',
);

if (citation != null) {
  print('APA: ${citation.apa}');
  print('MLA: ${citation.mla}');
  print('BibTeX: ${citation.bibtex}');
}
```

### Add Metadata Button to AppBar
```dart
AppBar(
  actions: [
    IconButton(
      icon: Icon(showMetadata ? Icons.info : Icons.info_outline),
      onPressed: () => setState(() => showMetadata = !showMetadata),
      tooltip: 'File Metadata',
    ),
  ],
)
```

### Add to Navigation Drawer
```dart
ListTile(
  leading: const Icon(Icons.format_quote),
  title: const Text('Citation Generator'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CitationGeneratorScreen(
          metadataService: Provider.of<MetadataService>(context),
        ),
      ),
    );
  },
)
```

## 🔧 Supported Identifiers

| Type | Example | API |
|------|---------|-----|
| DOI | `10.1038/nature12345` | CrossRef |
| arXiv | `2301.12345` | arXiv API |
| ISBN | `978-0-262-03384-8` | Open Library |
| PMID | `12345678` | PubMed |
| URL | `https://doi.org/10.1234/example` | Auto-detect |

## 📝 Citation Formats

- **APA** - American Psychological Association
- **MLA** - Modern Language Association
- **Chicago** - Chicago Manual of Style
- **BibTeX** - LaTeX bibliography format

## 🎯 Common Use Cases

### 1. Show Metadata in PDF Viewer
```dart
Row(
  children: [
    Expanded(child: PdfViewer(...)),
    if (showMetadata)
      FileMetadataSidebar(
        file: file,
        metadataService: metadataService,
        onClose: () => setState(() => showMetadata = false),
      ),
  ],
)
```

### 2. Quick Citation from File
```dart
// Extract metadata
final metadata = await metadataService.extractMetadata(
  fileId: file.id,
  fileName: file.name,
);

// Generate citation if DOI exists
if (metadata?.doi != null) {
  final citation = await metadataService.generateCitation(
    identifierType: 'doi',
    identifierValue: metadata!.doi!,
  );
}
```

### 3. Copy Citation to Clipboard
```dart
void copyCitation(String citation, String format) {
  Clipboard.setData(ClipboardData(text: citation));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$format citation copied')),
  );
}
```

## 🐛 Troubleshooting

### Metadata Not Extracted
- ✅ Check PDF has embedded metadata
- ✅ Verify file is accessible
- ✅ Check backend logs

### Citation Generation Fails
- ✅ Verify identifier is correct
- ✅ Check internet connection
- ✅ Try different identifier type
- ✅ Check external API status

### CORS Errors
```python
# backend/app/main.py
cors_origins = [
    "http://localhost:8080",  # Add your frontend URL
]
```

### 401 Unauthorized
- ✅ Verify user is logged in
- ✅ Check token is valid
- ✅ Ensure `getToken()` returns JWT

## 📊 Metadata Fields

```dart
class PDFMetadata {
  String? title;
  List<String> authors;
  int? publicationYear;
  String? journal;
  String? conference;
  String? doi;
  String? isbn;
  String? pmid;
  String? arxivId;
  String? abstract;
  List<String> keywords;
  String? pages;
  String? volume;
  String? issue;
  String? publisher;
  String? url;
  
  // File info
  String? fileId;
  String? fileName;
  int? fileSize;
  DateTime? createdTime;
  DateTime? modifiedTime;
}
```

## 🎨 Customization

### Change Sidebar Width
```dart
FileMetadataSidebar(
  file: file,
  metadataService: metadataService,
  width: 400, // Custom width
)
```

### Custom Citation Format
```dart
// Backend: Add to CitationService
@staticmethod
def _generate_custom(metadata: PDFMetadata) -> str:
    # Your custom format
    return f"{metadata.authors[0]} ({metadata.publication_year}). {metadata.title}"
```

### Mobile Bottom Sheet
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (_) => DraggableScrollableSheet(
    initialChildSize: 0.7,
    builder: (_, controller) => FileMetadataSidebar(
      file: file,
      metadataService: metadataService,
    ),
  ),
);
```

## 📚 Files Created

### Backend
- `backend/app/models/metadata.py`
- `backend/app/services/metadata_service.py`
- `backend/app/routers/metadata.py`

### Frontend
- `frontend/lib/models/pdf_metadata.dart`
- `frontend/lib/services/metadata_service.dart`
- `frontend/lib/widgets/file_metadata_sidebar.dart`
- `frontend/lib/screens/citation_generator_screen.dart`

### Documentation
- `CITATION_METADATA_FEATURE.md` - Full documentation
- `CITATION_INTEGRATION_GUIDE.md` - Integration guide
- `CITATION_METADATA_INTEGRATION_EXAMPLE.md` - Code examples
- `CITATION_QUICK_REFERENCE.md` - This file

## 🚦 Testing Checklist

- [ ] Backend endpoints respond correctly
- [ ] Metadata extraction works for PDFs
- [ ] Citation generation works for all identifier types
- [ ] Copy to clipboard works
- [ ] Sidebar opens/closes correctly
- [ ] Citation generator navigation works
- [ ] Error handling displays properly
- [ ] Mobile responsive layout works
- [ ] Offline behavior is graceful

## 🔗 External APIs Used

- **CrossRef** - DOI metadata (free, no key required)
- **arXiv** - Preprint metadata (free, no key required)
- **Open Library** - ISBN book data (free, no key required)
- **PubMed E-utilities** - Medical literature (free, no key required)

## 💡 Tips

1. **Cache metadata** to avoid repeated API calls
2. **Show loading states** during extraction/generation
3. **Handle errors gracefully** with retry options
4. **Test with various PDFs** to ensure compatibility
5. **Consider offline mode** for metadata extraction
6. **Add keyboard shortcuts** for power users
7. **Implement citation history** for frequently used citations

## 📞 Support

- API Docs: `http://localhost:8000/docs`
- Full Docs: `CITATION_METADATA_FEATURE.md`
- Integration: `CITATION_INTEGRATION_GUIDE.md`
- Examples: `CITATION_METADATA_INTEGRATION_EXAMPLE.md`
