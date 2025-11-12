# Citation & Metadata Integration Example

## Complete Integration Example for PDF Viewer

Here's how to add the metadata sidebar to your existing PDF viewer:

### Step 1: Update PDF Viewer Screen

Add these changes to `frontend/lib/screens/pdf_viewer_screen.dart`:

```dart
// Add imports at the top
import '../widgets/file_metadata_sidebar.dart';
import '../services/metadata_service.dart';

// In _PdfViewerScreenState class, add state variable:
bool _showMetadataSidebar = false;

// In the AppBar actions, add metadata button:
actions: [
  // ... existing actions (search, annotations, etc.)
  
  // Add metadata button
  IconButton(
    icon: Icon(
      _showMetadataSidebar ? Icons.info : Icons.info_outline,
      color: _showMetadataSidebar ? Theme.of(context).primaryColor : null,
    ),
    onPressed: () {
      setState(() {
        _showMetadataSidebar = !_showMetadataSidebar;
      });
    },
    tooltip: 'File Metadata',
  ),
],

// In the build method body, wrap your existing content:
body: Row(
  children: [
    // Existing PDF viewer content
    Expanded(
      child: Column(
        children: [
          // Your existing PDF viewer widgets
          // ... annotation toolbar, PDF viewer, etc.
        ],
      ),
    ),
    
    // Add metadata sidebar
    if (_showMetadataSidebar)
      FileMetadataSidebar(
        file: widget.file ?? DriveFile(
          id: widget.fileId!,
          name: widget.fileName!,
        ),
        metadataService: Provider.of<MetadataService>(context),
        onClose: () {
          setState(() {
            _showMetadataSidebar = false;
          });
        },
      ),
  ],
),
```

### Step 2: Add MetadataService to Provider Setup

In `frontend/lib/main.dart`:

```dart
import 'services/metadata_service.dart';

// In your MultiProvider:
MultiProvider(
  providers: [
    // Existing providers
    Provider<AuthService>(
      create: (_) => AuthService(),
    ),
    
    // Add MetadataService after AuthService
    ProxyProvider<AuthService, MetadataService>(
      update: (context, authService, previous) => MetadataService(
        baseUrl: const String.fromEnvironment(
          'BACKEND_URL',
          defaultValue: 'http://localhost:8000',
        ),
        getToken: () => authService.idToken ?? '',
      ),
    ),
    
    // ... other providers
  ],
  child: MyApp(),
)
```

### Step 3: Add Citation Generator to Navigation

#### Option A: Add to Drawer Menu

In your drawer widget (e.g., `frontend/lib/widgets/app_navigation.dart`):

```dart
import '../screens/citation_generator_screen.dart';
import '../services/metadata_service.dart';

// In the drawer's ListView:
ListTile(
  leading: const Icon(Icons.format_quote),
  title: const Text('Citation Generator'),
  subtitle: const Text('Generate citations from DOI, ISBN, etc.'),
  onTap: () {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CitationGeneratorScreen(
          metadataService: Provider.of<MetadataService>(
            context,
            listen: false,
          ),
        ),
      ),
    );
  },
),
```

#### Option B: Add to Home Screen

In `frontend/lib/screens/home_screen.dart`:

```dart
// Add to your grid of features:
GridView.count(
  crossAxisCount: 2,
  children: [
    // ... existing feature cards
    
    _buildFeatureCard(
      context,
      icon: Icons.format_quote,
      title: 'Citation Generator',
      subtitle: 'Generate formatted citations',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CitationGeneratorScreen(
              metadataService: Provider.of<MetadataService>(
                context,
                listen: false,
              ),
            ),
          ),
        );
      },
    ),
  ],
)
```

### Step 4: Add Citation Button to File Context Menu

In `frontend/lib/widgets/file_context_menu.dart`:

```dart
// Add to the popup menu items:
PopupMenuItem(
  child: const ListTile(
    leading: Icon(Icons.format_quote),
    title: Text('Generate Citation'),
    dense: true,
  ),
  onTap: () async {
    // Close menu first
    Navigator.pop(context);
    
    // Extract metadata and navigate to citation generator
    final metadataService = Provider.of<MetadataService>(
      context,
      listen: false,
    );
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    // Extract metadata
    final metadata = await metadataService.extractMetadata(
      fileId: file.id,
      fileName: file.name,
      extractFromContent: true,
    );
    
    // Close loading
    Navigator.pop(context);
    
    if (metadata != null && metadata.doi != null) {
      // Navigate to citation generator with pre-filled DOI
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CitationGeneratorScreen(
            metadataService: metadataService,
            initialIdentifierType: 'doi',
            initialIdentifierValue: metadata.doi,
          ),
        ),
      );
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No DOI found in PDF metadata'),
        ),
      );
    }
  },
),
```

### Step 5: Update Citation Generator to Accept Initial Values

Modify `frontend/lib/screens/citation_generator_screen.dart`:

```dart
class CitationGeneratorScreen extends StatefulWidget {
  final MetadataService metadataService;
  final String? initialIdentifierType;
  final String? initialIdentifierValue;

  const CitationGeneratorScreen({
    Key? key,
    required this.metadataService,
    this.initialIdentifierType,
    this.initialIdentifierValue,
  }) : super(key: key);

  @override
  State<CitationGeneratorScreen> createState() =>
      _CitationGeneratorScreenState();
}

class _CitationGeneratorScreenState extends State<CitationGeneratorScreen> {
  // ... existing code
  
  @override
  void initState() {
    super.initState();
    
    // Pre-fill if initial values provided
    if (widget.initialIdentifierType != null) {
      _selectedType = widget.initialIdentifierType!;
    }
    if (widget.initialIdentifierValue != null) {
      _identifierController.text = widget.initialIdentifierValue!;
      // Auto-generate citation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateCitation();
      });
    }
  }
  
  // ... rest of the code
}
```

## Complete Example: Minimal Integration

If you want a minimal working example, here's a standalone widget:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/drive_file.dart';
import '../services/metadata_service.dart';
import '../widgets/file_metadata_sidebar.dart';
import '../screens/citation_generator_screen.dart';

class PdfViewerWithMetadata extends StatefulWidget {
  final DriveFile file;
  
  const PdfViewerWithMetadata({Key? key, required this.file}) : super(key: key);
  
  @override
  State<PdfViewerWithMetadata> createState() => _PdfViewerWithMetadataState();
}

class _PdfViewerWithMetadataState extends State<PdfViewerWithMetadata> {
  bool _showMetadata = false;
  
  @override
  Widget build(BuildContext context) {
    final metadataService = Provider.of<MetadataService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
        actions: [
          // Metadata button
          IconButton(
            icon: Icon(_showMetadata ? Icons.info : Icons.info_outline),
            onPressed: () {
              setState(() => _showMetadata = !_showMetadata);
            },
            tooltip: 'File Metadata',
          ),
          
          // Citation generator button
          IconButton(
            icon: const Icon(Icons.format_quote),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CitationGeneratorScreen(
                    metadataService: metadataService,
                  ),
                ),
              );
            },
            tooltip: 'Citation Generator',
          ),
        ],
      ),
      body: Row(
        children: [
          // PDF Viewer
          Expanded(
            child: Center(
              child: Text('Your PDF Viewer Here'),
            ),
          ),
          
          // Metadata Sidebar
          if (_showMetadata)
            FileMetadataSidebar(
              file: widget.file,
              metadataService: metadataService,
              onClose: () => setState(() => _showMetadata = false),
            ),
        ],
      ),
    );
  }
}
```

## Testing the Integration

### 1. Test Metadata Sidebar

```dart
// Create a test file
final testFile = DriveFile(
  id: 'test_file_id',
  name: 'research_paper.pdf',
  mimeType: 'application/pdf',
);

// Navigate to PDF viewer
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => PdfViewerScreen(file: testFile),
  ),
);

// Click metadata button
// Verify sidebar opens
// Check metadata is displayed
// Test copy buttons
```

### 2. Test Citation Generator

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

// Test with DOI: 10.1038/nature12345
// Verify citations are generated
// Test copy buttons
```

## Responsive Design Considerations

### Mobile Layout

For mobile devices, consider using a bottom sheet instead of sidebar:

```dart
// Instead of sidebar in Row, use bottom sheet:
if (_showMetadata)
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => FileMetadataSidebar(
        file: widget.file,
        metadataService: metadataService,
        onClose: () => Navigator.pop(context),
      ),
    ),
  );
```

### Tablet Layout

For tablets, the sidebar works well:

```dart
// Use MediaQuery to determine layout
final isTablet = MediaQuery.of(context).size.width > 600;

if (_showMetadata && isTablet) {
  // Show sidebar
  FileMetadataSidebar(...)
} else if (_showMetadata) {
  // Show bottom sheet
  showModalBottomSheet(...)
}
```

## Error Handling

Add proper error handling:

```dart
try {
  final metadata = await metadataService.extractMetadata(
    fileId: file.id,
    fileName: file.name,
  );
  
  if (metadata == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not extract metadata from this PDF'),
        backgroundColor: Colors.orange,
      ),
    );
  }
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error: ${e.toString()}'),
      backgroundColor: Colors.red,
    ),
  );
}
```

## Performance Optimization

Cache metadata to avoid repeated extraction:

```dart
// In your state:
final Map<String, PDFMetadata> _metadataCache = {};

Future<PDFMetadata?> _getMetadata(String fileId, String fileName) async {
  // Check cache first
  if (_metadataCache.containsKey(fileId)) {
    return _metadataCache[fileId];
  }
  
  // Extract and cache
  final metadata = await metadataService.extractMetadata(
    fileId: fileId,
    fileName: fileName,
  );
  
  if (metadata != null) {
    _metadataCache[fileId] = metadata;
  }
  
  return metadata;
}
```

## Summary

You now have:
1. ✅ Backend API for metadata extraction and citation generation
2. ✅ Frontend models and services
3. ✅ File metadata sidebar widget
4. ✅ Citation generator screen
5. ✅ Integration examples for PDF viewer
6. ✅ Navigation integration examples
7. ✅ Responsive design considerations
8. ✅ Error handling patterns

The features are ready to use! Just follow the integration steps above to add them to your existing screens.
