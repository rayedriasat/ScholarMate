import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../database/database.dart';
import 'config_service.dart';

/// Service for tracking reading analytics
class AnalyticsService {
  final AppDatabase _database;
  final String _userId;
  final ConfigService _config = ConfigService();
  String? _currentSessionId;
  DateTime? _sessionStartTime;
  String? _currentFileId;
  int _currentPageNumber = 0;

  AnalyticsService(this._database, this._userId);

  /// Start a reading session
  Future<void> startSession(
    String fileId,
    String fileName,
    int? totalPages,
  ) async {
    await endSession(); // End any existing session

    _currentSessionId = const Uuid().v4();
    _sessionStartTime = DateTime.now();
    _currentFileId = fileId;
    _currentPageNumber = 0;

    await _database
        .into(_database.readingSessions)
        .insert(
          ReadingSessionsCompanion.insert(
            id: _currentSessionId!,
            userId: _userId,
            fileId: fileId,
            fileName: fileName,
            startTime: _sessionStartTime!,
            totalPages: Value(totalPages),
          ),
        );
  }

  /// Update current page being read
  Future<void> updateCurrentPage(int pageNumber) async {
    if (_currentFileId == null || _currentSessionId == null) return;

    _currentPageNumber = pageNumber;

    // Track page read history
    final pageId = '${_currentFileId}_$pageNumber';
    final existing = await (_database.select(
      _database.pageReadHistory,
    )..where((t) => t.id.equals(pageId))).getSingleOrNull();

    if (existing == null) {
      await _database
          .into(_database.pageReadHistory)
          .insert(
            PageReadHistoryCompanion.insert(
              id: pageId,
              userId: _userId,
              fileId: _currentFileId!,
              pageNumber: pageNumber,
              firstReadAt: DateTime.now(),
              lastReadAt: DateTime.now(),
            ),
          );
    } else {
      await (_database.update(
        _database.pageReadHistory,
      )..where((t) => t.id.equals(pageId))).write(
        PageReadHistoryCompanion(
          lastReadAt: Value(DateTime.now()),
          readCount: Value(existing.readCount + 1),
          isSynced: const Value(false),
        ),
      );
    }
  }

  /// End current reading session
  Future<void> endSession() async {
    if (_currentSessionId == null || _sessionStartTime == null) return;

    final endTime = DateTime.now();
    final duration = endTime.difference(_sessionStartTime!).inSeconds;

    await (_database.update(
      _database.readingSessions,
    )..where((t) => t.id.equals(_currentSessionId!))).write(
      ReadingSessionsCompanion(
        endTime: Value(endTime),
        durationSeconds: Value(duration),
        pagesRead: Value(_currentPageNumber),
        isSynced: const Value(false),
      ),
    );

    _currentSessionId = null;
    _sessionStartTime = null;
    _currentFileId = null;
    _currentPageNumber = 0;
  }

  /// Get total reading time in seconds
  Future<int> getTotalReadingTime() async {
    final sessions = await (_database.select(
      _database.readingSessions,
    )..where((t) => t.userId.equals(_userId))).get();

    return sessions.fold<int>(
      0,
      (sum, session) => sum + session.durationSeconds,
    );
  }

  /// Get total pages read across all files
  Future<int> getTotalPagesRead() async {
    final pages = await (_database.select(
      _database.pageReadHistory,
    )..where((t) => t.userId.equals(_userId))).get();

    return pages.length;
  }

  /// Get reading stats for a specific file
  Future<FileReadingStats> getFileStats(String fileId) async {
    final sessions = await (_database.select(
      _database.readingSessions,
    )..where((t) => t.fileId.equals(fileId) & t.userId.equals(_userId))).get();

    final pages = await (_database.select(
      _database.pageReadHistory,
    )..where((t) => t.fileId.equals(fileId) & t.userId.equals(_userId))).get();

    final totalTime = sessions.fold<int>(
      0,
      (sum, s) => s.durationSeconds + sum,
    );
    final uniquePages = pages.length;
    final totalReads = pages.fold<int>(0, (sum, p) => sum + p.readCount);

    return FileReadingStats(
      fileId: fileId,
      totalTimeSeconds: totalTime,
      uniquePagesRead: uniquePages,
      totalPageReads: totalReads,
      sessionCount: sessions.length,
    );
  }

  /// Get top read files
  Future<List<FileReadingStats>> getTopFiles({int limit = 10}) async {
    final sessions = await (_database.select(
      _database.readingSessions,
    )..where((t) => t.userId.equals(_userId))).get();

    final fileGroups = <String, List<ReadingSession>>{};
    for (final session in sessions) {
      fileGroups.putIfAbsent(session.fileId, () => []).add(session);
    }

    final stats = <FileReadingStats>[];
    for (final entry in fileGroups.entries) {
      final fileStats = await getFileStats(entry.key);
      stats.add(fileStats);
    }

    stats.sort((a, b) => b.totalTimeSeconds.compareTo(a.totalTimeSeconds));
    return stats.take(limit).toList();
  }

  /// Get reading activity by date
  Future<Map<DateTime, int>> getReadingActivityByDate({int days = 30}) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final sessions =
        await (_database.select(_database.readingSessions)..where(
              (t) =>
                  t.userId.equals(_userId) &
                  t.startTime.isBiggerOrEqualValue(startDate),
            ))
            .get();

    final activity = <DateTime, int>{};
    for (final session in sessions) {
      final date = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      activity[date] = (activity[date] ?? 0) + session.durationSeconds;
    }

    return activity;
  }

  /// Get reading streak (consecutive days)
  Future<int> getReadingStreak() async {
    final activity = await getReadingActivityByDate(days: 365);
    if (activity.isEmpty) return 0;

    final sortedDates = activity.keys.toList()..sort((a, b) => b.compareTo(a));

    int streak = 0;
    DateTime checkDate = DateTime.now();
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    for (int i = 0; i < 365; i++) {
      if (activity.containsKey(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  /// Sync unsynced analytics data to backend
  Future<void> syncToBackend() async {
    try {
      // Get unsynced sessions
      final unsyncedSessions =
          await (_database.select(_database.readingSessions)..where(
                (t) => t.userId.equals(_userId) & t.isSynced.equals(false),
              ))
              .get();

      // Get unsynced page reads
      final unsyncedPages =
          await (_database.select(_database.pageReadHistory)..where(
                (t) => t.userId.equals(_userId) & t.isSynced.equals(false),
              ))
              .get();

      if (unsyncedSessions.isEmpty && unsyncedPages.isEmpty) return;

      // Prepare sync data
      final syncData = {
        'sessions': unsyncedSessions
            .map(
              (s) => {
                'id': s.id,
                'file_id': s.fileId,
                'file_name': s.fileName,
                'start_time': s.startTime.toIso8601String(),
                'end_time': s.endTime?.toIso8601String(),
                'duration_seconds': s.durationSeconds,
                'pages_read': s.pagesRead,
                'total_pages': s.totalPages,
              },
            )
            .toList(),
        'page_reads': unsyncedPages
            .map(
              (p) => {
                'id': p.id,
                'file_id': p.fileId,
                'page_number': p.pageNumber,
                'first_read_at': p.firstReadAt.toIso8601String(),
                'last_read_at': p.lastReadAt.toIso8601String(),
                'read_count': p.readCount,
              },
            )
            .toList(),
      };

      // Sync to backend
      final response = await http.post(
        Uri.parse('${_config.apiBaseUrl}/api/analytics/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(syncData),
      );

      if (response.statusCode != 200) {
        throw Exception('Sync failed: ${response.body}');
      }

      // Mark as synced
      for (final session in unsyncedSessions) {
        await (_database.update(_database.readingSessions)
              ..where((t) => t.id.equals(session.id)))
            .write(const ReadingSessionsCompanion(isSynced: Value(true)));
      }

      for (final page in unsyncedPages) {
        await (_database.update(_database.pageReadHistory)
              ..where((t) => t.id.equals(page.id)))
            .write(const PageReadHistoryCompanion(isSynced: Value(true)));
      }
    } catch (e) {
      // Sync failed, will retry later
      print('Analytics sync failed: $e');
    }
  }
}

/// Reading statistics for a file
class FileReadingStats {
  final String fileId;
  final int totalTimeSeconds;
  final int uniquePagesRead;
  final int totalPageReads;
  final int sessionCount;

  FileReadingStats({
    required this.fileId,
    required this.totalTimeSeconds,
    required this.uniquePagesRead,
    required this.totalPageReads,
    required this.sessionCount,
  });

  String get formattedTime {
    final hours = totalTimeSeconds ~/ 3600;
    final minutes = (totalTimeSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
