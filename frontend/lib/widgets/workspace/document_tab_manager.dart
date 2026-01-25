import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../models/drive_file.dart';
import '../../services/pdf_viewer_manager.dart';
import 'package:provider/provider.dart';

/// Manages open document tabs (PDF and Markdown) and their state
class DocumentTabManager extends ChangeNotifier {
  final List<DocumentTab> _tabs = [];
  int _activeTabIndex = -1;

  List<DocumentTab> get tabs => List.unmodifiable(_tabs);
  int get activeTabIndex => _activeTabIndex;
  DocumentTab? get activeTab =>
      _activeTabIndex >= 0 && _activeTabIndex < _tabs.length
          ? _tabs[_activeTabIndex]
          : null;

  /// Open a file in a new tab or activate existing tab
  Future<void> openFile(
    BuildContext context,
    DriveFile file, {
    int? initialPage,
    String? searchQuery,
    String? highlightText,
  }) async {
    // Check if file is already open
    final existingIndex = _tabs.indexWhere((tab) => tab.file.id == file.id);

    if (existingIndex != -1) {
      // Activate existing tab
      _activeTabIndex = existingIndex;
      notifyListeners();
      return;
    }

    // Create new tab based on file type
    final tab = DocumentTab(
      file: file,
      initialPage: initialPage,
      searchQuery: searchQuery,
      highlightText: highlightText,
    );

    // Add tab immediately to show loading state
    _tabs.add(tab);
    _activeTabIndex = _tabs.length - 1;
    notifyListeners();

    // Load content based on file type
    if (file.isPdf) {
      final pdfManager = context.read<PdfViewerManager>();
      await pdfManager.loadPdf(file);

      if (pdfManager.currentPdfBytes != null) {
        tab.pdfBytes = pdfManager.currentPdfBytes;
        tab.isLoading = false;
        notifyListeners();
      } else {
        // Remove tab if loading failed
        _tabs.remove(tab);
        _activeTabIndex = _tabs.length - 1;
        notifyListeners();
      }
    } else if (file.isMarkdown) {
      // Markdown content will be loaded by the viewer widget
      tab.isLoading = false;
      notifyListeners();
    }
  }

  /// Close a tab
  void closeTab(int index) {
    if (index < 0 || index >= _tabs.length) return;

    final tab = _tabs[index];
    tab.dispose();
    _tabs.removeAt(index);

    // Adjust active tab index
    if (_activeTabIndex >= _tabs.length) {
      _activeTabIndex = _tabs.length - 1;
    }

    notifyListeners();
  }

  /// Set active tab
  void setActiveTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _activeTabIndex = index;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final tab in _tabs) {
      tab.dispose();
    }
    _tabs.clear();
    super.dispose();
  }
}

/// Represents a single document tab with its state
class DocumentTab {
  final DriveFile file;
  final PdfViewerController? controller;
  final GlobalKey<SfPdfViewerState>? viewerKey;
  final int? initialPage;
  final String? searchQuery;
  final String? highlightText;

  Uint8List? pdfBytes;
  int currentPage = 1;
  int totalPages = 0;
  double zoomLevel = 1.0;
  bool showOutline = false;
  bool isLoading = true;
  dynamic bookmarks; // PdfBookmarkBase from syncfusion_flutter_pdfviewer
  PdfTextSearchResult? searchResult;

  DocumentTab({
    required this.file,
    this.initialPage,
    this.searchQuery,
    this.highlightText,
  }) : controller = file.isPdf ? PdfViewerController() : null,
       viewerKey = file.isPdf ? GlobalKey<SfPdfViewerState>() : null;

  bool get isPdf => file.isPdf;
  bool get isMarkdown => file.isMarkdown;

  void dispose() {
    controller?.dispose();
  }
}

/// Legacy type alias for backward compatibility
typedef PdfTabManager = DocumentTabManager;
typedef PdfTab = DocumentTab;
