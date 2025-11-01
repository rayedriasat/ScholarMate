import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/indexing_job.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Service for managing RAG indexing operations
class IndexingService extends ChangeNotifier {
  final ApiService _apiService;
  final AuthService _authService;

  // Map of file_id -> IndexingJob for quick lookup
  final Map<String, IndexingJob> _jobsByFileId = {};

  // List of all jobs
  List<IndexingJob> _allJobs = [];

  Timer? _pollingTimer;
  bool _isPolling = false;

  IndexingService({
    required ApiService apiService,
    required AuthService authService,
  })  : _apiService = apiService,
        _authService = authService;

  /// Get all jobs
  List<IndexingJob> get allJobs => List.unmodifiable(_allJobs);

  /// Get job for a specific file
  IndexingJob? getJobForFile(String fileId) => _jobsByFileId[fileId];

  /// Get indexing status for a file
  String getFileIndexingStatus(String fileId) {
    final job = _jobsByFileId[fileId];
    if (job == null) return 'not_indexed';
    return job.status;
  }

  /// Check if a file is indexed
  bool isFileIndexed(String fileId) {
    final job = _jobsByFileId[fileId];
    return job != null && job.isCompleted;
  }

  /// Check if a file is currently indexing
  bool isFileIndexing(String fileId) {
    final job = _jobsByFileId[fileId];
    return job != null && job.isActive;
  }

  /// Get progress percentage for a file
  double getFileProgress(String fileId) {
    final job = _jobsByFileId[fileId];
    return job?.progressPercentage ?? 0.0;
  }

  /// Start indexing a file
  Future<String> startIndexing({
    required String fileId,
    String? fileName,
  }) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final jobId = await _apiService.startIndexing(
        userId: userId,
        fileId: fileId,
        fileName: fileName,
      );

      // Start polling for updates
      _startPolling();

      // Refresh jobs list
      await refreshJobs();

      return jobId;
    } catch (e) {
      debugPrint('Failed to start indexing: $e');
      rethrow;
    }
  }

  /// Reindex a file
  Future<String> reindexFile({
    required String fileId,
    String? fileName,
  }) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final jobId = await _apiService.reindexFile(
        userId: userId,
        fileId: fileId,
        fileName: fileName,
      );

      // Start polling for updates
      _startPolling();

      // Refresh jobs list
      await refreshJobs();

      return jobId;
    } catch (e) {
      debugPrint('Failed to reindex file: $e');
      rethrow;
    }
  }

  /// Reindex all PDF files
  Future<List<String>> reindexAllFiles(List<String> fileIds) async {
    final jobIds = <String>[];

    for (final fileId in fileIds) {
      try {
        final jobId = await reindexFile(fileId: fileId);
        jobIds.add(jobId);
      } catch (e) {
        debugPrint('Failed to reindex file $fileId: $e');
      }
    }

    return jobIds;
  }

  /// Refresh jobs list from backend
  Future<void> refreshJobs() async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) return;

      final jobs = await _apiService.listUserJobs(userId: userId);

      _allJobs = jobs;
      _jobsByFileId.clear();

      // Build file_id -> job map (keep only the latest job per file)
      for (final job in jobs) {
        final existingJob = _jobsByFileId[job.fileId];
        if (existingJob == null ||
            job.createdAt.isAfter(existingJob.createdAt)) {
          _jobsByFileId[job.fileId] = job;
        }
      }

      notifyListeners();

      // Stop polling if no active jobs
      if (!_hasActiveJobs()) {
        _stopPolling();
      }
    } catch (e) {
      debugPrint('Failed to refresh jobs: $e');
    }
  }

  /// Get job status by job ID
  Future<IndexingJob?> getJobStatus(String jobId) async {
    try {
      final job = await _apiService.getJobStatus(jobId: jobId);
      return job;
    } catch (e) {
      debugPrint('Failed to get job status: $e');
      return null;
    }
  }

  /// Start polling for job updates
  void _startPolling() {
    if (_isPolling) return;

    _isPolling = true;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      refreshJobs();
    });
  }

  /// Stop polling for job updates
  void _stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Check if there are any active jobs
  bool _hasActiveJobs() {
    return _allJobs.any((job) => job.isActive);
  }

  /// Get count of active jobs
  int get activeJobCount => _allJobs.where((job) => job.isActive).length;

  /// Get count of completed jobs
  int get completedJobCount => _allJobs.where((job) => job.isCompleted).length;

  /// Get count of failed jobs
  int get failedJobCount => _allJobs.where((job) => job.isFailed).length;

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
