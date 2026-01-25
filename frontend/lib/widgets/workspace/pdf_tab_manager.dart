import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../models/drive_file.dart';
import '../../services/pdf_viewer_manager.dart';
import 'package:provider/provider.dart';

// Re-export new manager for backward compatibility
export 'document_tab_manager.dart';

/// DEPRECATED: Use DocumentTabManager instead
/// Manages open PDF tabs and their state
@Deprecated('Use DocumentTabManager from document_tab_manager.dart instead')
class PdfTabManager extends ChangeNotifier {
  final List<PdfTab> _tabs = [];
  int _activeTabIndex = -1;

  List<PdfTab> get tabs => List.unmodifiable(_tabs);
  int get activeTabIndex => _activeTabIndex;
  PdfTab? get activeTab =>
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

    // Create new tab with loading state
    final tab = PdfTab(
      file: file,
      initialPage: initialPage,
      searchQuery: searchQuery,
      highlightText: highlightText,
    );

    // Add tab immediately to show loading state
    _tabs.add(tab);
    _activeTabIndex = _tabs.length - 1;
    notifyListeners();

    // Load PDF in background
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

/// DEPRECATED: Use DocumentTab instead
/// Represents a single PDF tab with its state
@Deprecated('Use DocumentTab from document_tab_manager.dart instead')
class PdfTab {
  final DriveFile file;
  final PdfViewerController controller;
  final GlobalKey<SfPdfViewerState> viewerKey;
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

  PdfTab({
    required this.file,
    this.initialPage,
    this.searchQuery,
    this.highlightText,
  }) : controller = PdfViewerController(),
       viewerKey = GlobalKey<SfPdfViewerState>();

  void dispose() {
    controller.dispose();
  }
}
