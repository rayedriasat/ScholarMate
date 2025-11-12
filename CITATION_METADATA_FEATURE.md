# Citation Generator & File Metadata Feature

## Overview

Two new features have been added to ScholarMate to enhance research workflow:

1. **File Metadata Sidebar**: Displays extracted PDF metadata when viewing files
2. **Citation Generator**: Generates formatted citations from various identifiers

## Features

### 1. File Metadata Sidebar

**Purpose**: Automatically extract and display metadata from PDF files

**Supported Metadata**:
- Title
- Authors
- Publication Year
- Journal/Conference Name
- DOI (Digital Object Identifier)
- ISBN (for books)
- PubMed ID (PMID)
- arXiv ID
- Abstract
- Keywords
- Volume, Issue, Pages
- Publisher
- File information (name, size, dates)

**How to Use**:
1. Open a PDF file in the viewer
2. Click the "Metadata" button or icon
3. The sidebar opens on the right showing extracted metadata
4. Click copy icons to copy individual fields
5. Click on DOI/PMID/arXiv links to open in browser

**Extraction Methods**:
- PDF document properties (embedded metadata)
- First page content parsing (for DOI, arXiv ID, etc.)
- Automatic detection of common academic paper formats

### 2. Citation Generator

**Purpose**: Generate formatted citations from various academic identifiers

**Supported Identifiers**:
- **DOI**: Digital Object Identifier (e.g., `10.1234/example`)
- **arXiv ID**: arXiv preprint identifier (e.g., `2301.12345`)
- **ISBN**: International Standard Book Number (e.g., `978-0-123456-78-9`)
- **PubMed ID**: PMID from PubMed database (e.g., `12345678`)
- **URL**: Web address containing DOI or arXiv ID

**Citation Formats**:
- **APA** (American Psychological Association)
- **MLA** (Modern Language Association)
- **Chicago** (Chicago Manual of Style)
- **BibTeX** (for LaTeX documents)

**How to Use**:
1. Navigate to Citation Generator (from menu or toolbar)
2. Select identifier type from dropdown
3. Enter the identifier value
4. Click "Generate Citations"
5. View all citation formats
6. Click copy button next to each format to copy to clipboard

**Example Workflow**:
```
1. User has a DOI: 10.1038/nature12345
2. Select "DOI" from dropdown
3. Enter: 10.1038/nature12345
4. Click "Generate Citations"
5. Get formatted citations in APA, MLA, Chicago, and BibTeX
6. Copy desired format to clipboard
```

## API Endpoints

### Backend Routes

#### Extract Metadata
```
POST /api/metadata/extract
Authorization: Bearer <token>

Request:
{
  "file_id": "google_drive_file_id",
  "file_name": "paper.pdf",
  "extract_from_content": true
}

Response:
{
  "title": "Example Paper Title",
  "authors": ["John Doe", "Jane Smith"],
  "publication_year": 2023,
  "journal": "Nature",
  "doi": "10.1234/example",
  ...
}
```

#### Generate Citation from Identifier
```
POST /api/metadata/citation/generate
Authorization: Bearer <token>

Request:
{
  "identifier_type": "doi",
  "identifier_value": "10.1234/example"
}

Response:
{
  "apa": "Doe, J., & Smith, J. (2023). Example Paper Title. Nature, 123(4), 567-890. https://doi.org/10.1234/example",
  "mla": "Doe, John. \"Example Paper Title.\" Nature, vol. 123, no. 4, 2023, pp. 567-890. doi:10.1234/example.",
  "chicago": "Doe, John. \"Example Paper Title.\" Nature 123, no. 4 (2023): 567-890. https://doi.org/10.1234/example.",
  "bibtex": "@article{doe2023,\n  title = {Example Paper Title},\n  author = {John Doe and Jane Smith},\n  ...\n}",
  "metadata": { ... }
}
```

#### Generate Citation from Metadata
```
POST /api/metadata/citation/from-metadata
Authorization: Bearer <token>

Request:
{
  "title": "Example Paper",
  "authors": ["John Doe"],
  "publication_year": 2023,
  ...
}

Response:
{
  "apa": "...",
  "mla": "...",
  "chicago": "...",
  "bibtex": "..."
}
```

## Implementation Details

### Backend

**New Files**:
- `backend/app/models/metadata.py` - Pydantic models for metadata and citations
- `backend/app/services/metadata_service.py` - Metadata extraction logic
- `backend/app/services/citation_service.py` - Citation generation logic (included in metadata_service.py)
- `backend/app/routers/metadata.py` - API endpoints

**External APIs Used**:
- **CrossRef API**: For DOI metadata lookup
- **arXiv API**: For arXiv paper metadata
- **Open Library API**: For ISBN book metadata
- **PubMed E-utilities**: For PubMed article metadata

**Dependencies**:
- `pypdf` - PDF parsing (already installed)
- `requests` - HTTP requests (already installed)

### Frontend

**New Files**:
- `frontend/lib/models/pdf_metadata.dart` - Data models
- `frontend/lib/services/metadata_service.dart` - API client
- `frontend/lib/widgets/file_metadata_sidebar.dart` - Sidebar widget
- `frontend/lib/screens/citation_generator_screen.dart` - Citation generator UI

**Integration Points**:
1. Add metadata button to PDF viewer toolbar
2. Add citation generator to main navigation menu
3. Provide MetadataService via Provider pattern

## Usage Examples

### Example 1: View PDF Metadata

```dart
// In PDF viewer screen
FileMetadataSidebar(
  file: currentFile,
  metadataService: Provider.of<MetadataService>(context),
  onClose: () => setState(() => showMetadata = false),
)
```

### Example 2: Generate Citation

```dart
// Navigate to citation generator
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CitationGeneratorScreen(
      metadataService: Provider.of<MetadataService>(context),
    ),
  ),
);
```

### Example 3: Extract Metadata Programmatically

```dart
final metadata = await metadataService.extractMetadata(
  fileId: file.id,
  fileName: file.name,
  extractFromContent: true,
);

if (metadata != null) {
  print('Title: ${metadata.title}');
  print('Authors: ${metadata.formattedAuthors}');
}
```

## Offline Support

**Metadata Extraction**:
- ✅ Works offline (extracts from local PDF file)
- Requires file to be cached in Drift database

**Citation Generation**:
- ❌ Requires internet connection (fetches from external APIs)
- Shows clear error message when offline
- Can generate citations from already-extracted metadata offline

## Testing

### Test Metadata Extraction

1. Upload a PDF with embedded metadata
2. Open the PDF in viewer
3. Click metadata button
4. Verify all fields are displayed correctly
5. Test copy functionality

### Test Citation Generator

**Test DOI**:
```
DOI: 10.1038/nature12345
Expected: Fetch metadata from CrossRef and generate citations
```

**Test arXiv**:
```
arXiv ID: 2301.12345
Expected: Fetch metadata from arXiv and generate citations
```

**Test ISBN**:
```
ISBN: 978-0-262-03384-8
Expected: Fetch book metadata from Open Library
```

**Test PMID**:
```
PMID: 12345678
Expected: Fetch article metadata from PubMed
```

**Test URL**:
```
URL: https://doi.org/10.1038/nature12345
Expected: Extract DOI and fetch metadata
```

## Future Enhancements

1. **Batch Citation Generation**: Generate citations for multiple papers at once
2. **Custom Citation Styles**: Allow users to define custom citation formats
3. **Citation Export**: Export citations to .bib, .ris, or .enw files
4. **Metadata Editing**: Allow users to manually edit extracted metadata
5. **Citation History**: Save previously generated citations
6. **Integration with PDF Viewer**: Generate citation directly from open PDF
7. **Offline Citation Database**: Cache citation data for offline access
8. **More Citation Styles**: Add Harvard, Vancouver, IEEE, etc.

## Troubleshooting

### Metadata Not Extracted

**Problem**: Sidebar shows "No metadata available"

**Solutions**:
- Ensure PDF has embedded metadata
- Try a different PDF
- Check backend logs for errors
- Verify file is accessible in Google Drive

### Citation Generation Fails

**Problem**: "Could not generate citation" error

**Solutions**:
- Verify identifier is correct
- Check internet connection
- Try a different identifier type
- Check if external API is available
- Verify backend has internet access

### Copy to Clipboard Not Working

**Problem**: Copy button doesn't work

**Solutions**:
- Check browser/platform clipboard permissions
- Try selecting text manually
- Verify Clipboard API is available

## Configuration

### Backend Environment Variables

No additional environment variables required. Uses existing:
- `BACKEND_URL` - Backend API URL
- Authentication tokens from existing auth system

### Frontend Configuration

Add MetadataService to Provider setup:

```dart
MultiProvider(
  providers: [
    // ... existing providers
    Provider<MetadataService>(
      create: (_) => MetadataService(
        baseUrl: backendUrl,
        getToken: () => authService.token,
      ),
    ),
  ],
  child: MyApp(),
)
```

## Performance Considerations

1. **Metadata Extraction**: Fast (< 1 second for most PDFs)
2. **Citation Generation**: Depends on external API response time (1-3 seconds)
3. **Caching**: Consider caching extracted metadata in Drift database
4. **Rate Limiting**: External APIs may have rate limits

## Security

1. **Authentication**: All endpoints require valid JWT token
2. **Authorization**: Users can only access their own files
3. **Input Validation**: All identifiers validated before API calls
4. **Error Handling**: No sensitive information in error messages
5. **HTTPS**: All external API calls use HTTPS

## Accessibility

1. **Screen Readers**: All buttons and fields have proper labels
2. **Keyboard Navigation**: Full keyboard support
3. **Color Contrast**: Meets WCAG AA standards
4. **Focus Indicators**: Clear focus states for all interactive elements
5. **Semantic HTML**: Proper heading hierarchy and ARIA labels
