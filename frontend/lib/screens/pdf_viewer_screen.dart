import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/drive_file.dart';
import '../services/pdf_viewer_manager.dart';

/// Full-screen PDF viewer with navigation controls
class PdfViewerScreen extends StatefulWidget {
  final DriveFile file;

  const PdfViewerScreen({super.key, required this.file});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  int _currentPage = 1;
  int _totalPages = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    final pdfManager = context.read<PdfViewerManager>();
    await pdfManager.loadPdf(widget.file);
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _jumpToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _pdfViewerController.jumpToPage(page);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _pdfViewerController.nextPage();
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _pdfViewerController.previousPage();
    }
  }

  void _showPageNavigator() {
    showDialog(
      context: context,
      builder: (context) {
        int targetPage = _currentPage;
        return AlertDialog(
          title: const Text('Go to Page'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Page number (1-$_totalPages)',
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              targetPage = int.tryParse(value) ?? _currentPage;
            },
            onSubmitted: (value) {
              final page = int.tryParse(value);
              if (page != null) {
                Navigator.pop(context);
                _jumpToPage(page);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _jumpToPage(targetPage);
              },
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _pdfViewerController.clearSelection();
      }
    });
  }

  void _performSearch() {
    if (_searchController.text.isNotEmpty) {
      _pdfViewerController.searchText(_searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.file.name,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            if (_totalPages > 0)
              Text(
                'Page $_currentPage of $_totalPages',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        actions: [
          // Search button
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
            tooltip: 'Search',
          ),
          // Page navigator
          IconButton(
            icon: const Icon(Icons.format_list_numbered),
            onPressed: _totalPages > 0 ? _showPageNavigator : null,
            tooltip: 'Go to page',
          ),
        ],
      ),
      body: Consumer<PdfViewerManager>(
        builder: (context, pdfManager, child) {
          if (pdfManager.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    pdfManager.downloadProgress < 1.0
                        ? 'Downloading... ${(pdfManager.downloadProgress * 100).toStringAsFixed(0)}%'
                        : 'Loading PDF...',
                  ),
                  if (pdfManager.downloadProgress > 0 &&
                      pdfManager.downloadProgress < 1.0)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      child: LinearProgressIndicator(
                        value: pdfManager.downloadProgress,
                      ),
                    ),
                ],
              ),
            );
          }

          if (pdfManager.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load PDF',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pdfManager.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadPdf,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (pdfManager.currentPdfBytes == null) {
            return const Center(child: Text('No PDF loaded'));
          }

          return Column(
            children: [
              // Search bar
              if (_isSearching)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.grey[200],
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: 'Search in PDF...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onSubmitted: (_) => _performSearch(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _performSearch,
                        tooltip: 'Search',
                      ),
                    ],
                  ),
                ),
              // Cached indicator
              if (pdfManager.isFromCache)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  color: Colors.green[100],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.offline_pin,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Viewing cached version',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              // PDF Viewer
              Expanded(
                child: SfPdfViewer.memory(
                  pdfManager.currentPdfBytes!,
                  key: _pdfViewerKey,
                  controller: _pdfViewerController,
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    setState(() {
                      _totalPages = details.document.pages.count;
                    });
                  },
                  onPageChanged: (PdfPageChangedDetails details) {
                    setState(() {
                      _currentPage = details.newPageNumber;
                    });
                  },
                ),
              ),
              // Bottom navigation bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Previous page button
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentPage > 1 ? _previousPage : null,
                          tooltip: 'Previous page',
                        ),
                        // Page slider
                        if (_totalPages > 0)
                          Expanded(
                            child: Slider(
                              value: _currentPage.toDouble(),
                              min: 1,
                              max: _totalPages.toDouble(),
                              divisions: _totalPages > 1 ? _totalPages - 1 : 1,
                              label: 'Page $_currentPage',
                              onChanged: (value) {
                                _jumpToPage(value.round());
                              },
                            ),
                          ),
                        // Next page button
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _currentPage < _totalPages
                              ? _nextPage
                              : null,
                          tooltip: 'Next page',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
