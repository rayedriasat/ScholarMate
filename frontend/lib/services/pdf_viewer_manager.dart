import 'package:flutter/foundation.dart';
import '../models/drive_file.dart';
import 'cache_service.dart';
import 'drive_service.dart';
import 'connectivity_service.dart';

/// Service for managing PDF loading and caching
class PdfViewerManager extends ChangeNotifier {
  final CacheService _cacheService;
  final DriveService _driveService;
  final ConnectivityService _connectivityService;

  PdfViewerManager({
    required CacheService cacheService,
    required DriveService driveService,
    required ConnectivityService connectivityService,
  }) : _cacheService = cacheService,
       _driveService = driveService,
       _connectivityService = connectivityService;

  // Current PDF state
  Uint8List? _currentPdfBytes;
  DriveFile? _currentFile;
  bool _isLoading = false;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  bool _isFromCache = false;

  // Getters
  Uint8List? get currentPdfBytes => _currentPdfBytes;
  DriveFile? get currentFile => _currentFile;
  bool get isLoading => _isLoading;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  bool get isFromCache => _isFromCache;
  CacheService get cacheService => _cacheService;

  /// Load PDF from cache or download from Drive
  Future<Uint8List?> loadPdf(DriveFile file) async {
    _currentFile = file;
    _isLoading = true;
    _errorMessage = null;
    _downloadProgress = 0.0;
    _isFromCache = false;
    notifyListeners();

    try {
      // First, try to load from cache
      final cachedPdf = await _cacheService.getCachedPdf(file.id);

      if (cachedPdf != null) {
        debugPrint('PDF loaded from cache: ${file.name}');
        _currentPdfBytes = cachedPdf;
        _isFromCache = true;
        _downloadProgress = 1.0;
        _isLoading = false;
        notifyListeners();
        return cachedPdf;
      }

      // If not cached and offline, return error
      if (!_connectivityService.isOnline) {
        throw Exception('PDF not cached and device is offline');
      }

      // Download from Drive
      debugPrint('Downloading PDF from Drive: ${file.name}');
      final pdfBytes = await _driveService.downloadFile(
        file.id,
        onProgress: (progress) {
          _downloadProgress = progress;
          notifyListeners();
        },
      );

      if (pdfBytes == null) {
        throw Exception('Failed to download PDF');
      }

      // Cache the PDF for offline access
      await _cacheService.cachePdfBytes(file.id, pdfBytes);
      debugPrint('PDF cached successfully: ${file.name}');

      _currentPdfBytes = pdfBytes;
      _isFromCache = false;
      _downloadProgress = 1.0;
      _isLoading = false;
      notifyListeners();
      return pdfBytes;
    } catch (e) {
      debugPrint('Error loading PDF: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Clear current PDF
  void clearPdf() {
    _currentPdfBytes = null;
    _currentFile = null;
    _isLoading = false;
    _downloadProgress = 0.0;
    _errorMessage = null;
    _isFromCache = false;
    notifyListeners();
  }

  /// Check if a PDF is cached
  Future<bool> isPdfCached(String fileId) async {
    final cachedPdf = await _cacheService.getCachedPdf(fileId);
    return cachedPdf != null;
  }

  /// Get cache size for a PDF
  Future<int?> getCachedPdfSize(String fileId) async {
    final cachedPdf = await _cacheService.getCachedPdf(fileId);
    return cachedPdf?.length;
  }
}
