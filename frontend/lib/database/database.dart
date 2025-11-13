import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'database.g.dart';

/// Main database class for ScholarMate
/// Supports all platforms including web using Drift
@DriftDatabase(
  tables: [
    Files,
    CachedPdfs,
    Annotations,
    SyncQueue,
    Tags,
    FileTags,
    ChatSourcePreferences,
    ChatConversations,
    ChatMessages,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Constructor for testing with custom executor
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Migration from version 1 to 2
          // Add any schema changes here if needed
        }
        if (from < 3) {
          // Migration from version 2 to 3: Add author fields to annotations
          await m.addColumn(annotations, annotations.authorId);
          await m.addColumn(annotations, annotations.authorName);
        }
        if (from < 4) {
          // Migration from version 3 to 4: Add tags and file_tags tables
          await m.createTable(tags);
          await m.createTable(fileTags);
        }
        if (from < 5) {
          // Migration from version 4 to 5: Add chat_source_preferences table
          await m.createTable(chatSourcePreferences);
        }
        if (from < 6) {
          // Migration from version 5 to 6: Add chat history tables
          await m.createTable(chatConversations);
          await m.createTable(chatMessages);
        }
      },
    );
  }

  // File operations
  Future<List<File>> getFiles([String? parentId]) {
    if (parentId != null) {
      return (select(files)
            ..where((f) => f.parentId.equals(parentId))
            ..orderBy([
              (f) =>
                  OrderingTerm(expression: f.isFolder, mode: OrderingMode.desc),
              (f) => OrderingTerm(expression: f.name),
            ]))
          .get();
    } else {
      return (select(files)
            ..where((f) => f.parentId.isNull())
            ..orderBy([
              (f) =>
                  OrderingTerm(expression: f.isFolder, mode: OrderingMode.desc),
              (f) => OrderingTerm(expression: f.name),
            ]))
          .get();
    }
  }

  Future<File?> getFile(String fileId) {
    return (select(files)..where((f) => f.id.equals(fileId))).getSingleOrNull();
  }

  Future<int> insertFile(FilesCompanion file) {
    return into(files).insert(file, mode: InsertMode.insertOrReplace);
  }

  Future<void> insertFiles(List<FilesCompanion> fileList) async {
    await batch((batch) {
      batch.insertAll(files, fileList, mode: InsertMode.insertOrReplace);
    });
  }

  Future<int> updateFile(FilesCompanion file) {
    return (update(
      files,
    )..where((f) => f.id.equals(file.id.value))).write(file);
  }

  Future<int> deleteFile(String fileId) {
    return (delete(files)..where((f) => f.id.equals(fileId))).go();
  }

  // Cached PDF operations
  Future<CachedPdf?> getCachedPdf(String fileId) {
    return (select(
      cachedPdfs,
    )..where((p) => p.fileId.equals(fileId))).getSingleOrNull();
  }

  Future<int> insertCachedPdf(CachedPdfsCompanion pdf) {
    return into(cachedPdfs).insert(pdf, mode: InsertMode.insertOrReplace);
  }

  Future<bool> isPdfCached(String fileId) async {
    final result =
        await (select(cachedPdfs)
              ..where((p) => p.fileId.equals(fileId))
              ..limit(1))
            .getSingleOrNull();
    return result != null;
  }

  Future<int> deleteCachedPdf(String fileId) {
    return (delete(cachedPdfs)..where((p) => p.fileId.equals(fileId))).go();
  }

  // Annotation operations
  Future<List<Annotation>> getAnnotations(String fileId) {
    return (select(annotations)
          ..where((a) => a.fileId.equals(fileId))
          ..orderBy([
            (a) => OrderingTerm(expression: a.pageNumber),
            (a) => OrderingTerm(expression: a.createdAt),
          ]))
        .get();
  }

  Future<List<Annotation>> getUnsyncedAnnotations() {
    return (select(annotations)..where((a) => a.isSynced.equals(false))).get();
  }

  Future<int> insertAnnotation(AnnotationsCompanion annotation) {
    return into(
      annotations,
    ).insert(annotation, mode: InsertMode.insertOrReplace);
  }

  Future<int> updateAnnotation(AnnotationsCompanion annotation) {
    return (update(
      annotations,
    )..where((a) => a.id.equals(annotation.id.value))).write(annotation);
  }

  Future<int> markAnnotationSynced(String annotationId) {
    return (update(annotations)..where((a) => a.id.equals(annotationId))).write(
      const AnnotationsCompanion(isSynced: Value(true)),
    );
  }

  Future<int> deleteAnnotation(String annotationId) {
    return (delete(annotations)..where((a) => a.id.equals(annotationId))).go();
  }

  // Sync queue operations
  Future<List<SyncQueueData>> getPendingSyncOperations() {
    return (select(syncQueue)..where((s) => s.status.equals('pending'))).get();
  }

  Future<int> insertSyncOperation(SyncQueueCompanion operation) {
    return into(syncQueue).insert(operation);
  }

  Future<int> updateSyncOperation(SyncQueueCompanion operation) {
    return (update(
      syncQueue,
    )..where((s) => s.id.equals(operation.id.value))).write(operation);
  }

  Future<int> deleteSyncOperation(int operationId) {
    return (delete(syncQueue)..where((s) => s.id.equals(operationId))).go();
  }

  // Cache statistics
  Future<Map<String, int>> getCacheStats() async {
    final fileCount = await (selectOnly(files)..addColumns([files.id.count()]))
        .getSingle()
        .then((row) => row.read(files.id.count()) ?? 0);

    final cachedPdfCount =
        await (selectOnly(cachedPdfs)..addColumns([cachedPdfs.fileId.count()]))
            .getSingle()
            .then((row) => row.read(cachedPdfs.fileId.count()) ?? 0);

    final annotationCount =
        await (selectOnly(annotations)..addColumns([annotations.id.count()]))
            .getSingle()
            .then((row) => row.read(annotations.id.count()) ?? 0);

    final totalSize =
        await (selectOnly(cachedPdfs)..addColumns([cachedPdfs.fileSize.sum()]))
            .getSingle()
            .then((row) => row.read(cachedPdfs.fileSize.sum()) ?? 0);

    return {
      'file_count': fileCount,
      'cached_pdf_count': cachedPdfCount,
      'annotation_count': annotationCount,
      'total_cache_size': totalSize,
    };
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    await delete(cachedPdfs).go();
    await delete(annotations).go();
    await delete(files).go();
    await delete(syncQueue).go();
    await delete(tags).go();
    await delete(fileTags).go();
  }

  // Tag operations
  Future<List<Tag>> getTags() {
    return (select(
      tags,
    )..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
  }

  Future<Tag?> getTag(String tagId) {
    return (select(tags)..where((t) => t.id.equals(tagId))).getSingleOrNull();
  }

  Future<int> insertTag(TagsCompanion tag) {
    return into(tags).insert(tag, mode: InsertMode.insertOrReplace);
  }

  Future<int> updateTag(TagsCompanion tag) {
    return (update(tags)..where((t) => t.id.equals(tag.id.value))).write(tag);
  }

  Future<int> deleteTag(String tagId) {
    return (delete(tags)..where((t) => t.id.equals(tagId))).go();
  }

  // File tag operations
  Future<List<FileTag>> getFileTagsByFile(String fileId) {
    return (select(fileTags)..where((ft) => ft.fileId.equals(fileId))).get();
  }

  Future<List<FileTag>> getFileTagsByTag(String tagId) {
    return (select(fileTags)..where((ft) => ft.tagId.equals(tagId))).get();
  }

  Future<int> insertFileTag(FileTagsCompanion fileTag) {
    return into(fileTags).insert(fileTag, mode: InsertMode.insertOrReplace);
  }

  Future<int> deleteFileTag(String fileId, String tagId) {
    return (delete(
      fileTags,
    )..where((ft) => ft.fileId.equals(fileId) & ft.tagId.equals(tagId))).go();
  }

  Future<int> deleteFileTagsByFile(String fileId) {
    return (delete(fileTags)..where((ft) => ft.fileId.equals(fileId))).go();
  }

  Future<int> deleteFileTagsByTag(String tagId) {
    return (delete(fileTags)..where((ft) => ft.tagId.equals(tagId))).go();
  }

  // Get files by tags with filter mode
  Future<List<File>> getFilesByTags(
    List<String> tagIds, {
    bool matchAll = false,
  }) async {
    if (tagIds.isEmpty) {
      return getFiles();
    }

    if (!matchAll) {
      // OR logic: files with ANY of the selected tags
      final fileTagRecords = await (select(
        fileTags,
      )..where((ft) => ft.tagId.isIn(tagIds))).get();

      final fileIds = fileTagRecords.map((ft) => ft.fileId).toSet().toList();

      if (fileIds.isEmpty) return [];

      return (select(files)
            ..where((f) => f.id.isIn(fileIds))
            ..orderBy([
              (f) =>
                  OrderingTerm(expression: f.isFolder, mode: OrderingMode.desc),
              (f) => OrderingTerm(expression: f.name),
            ]))
          .get();
    } else {
      // AND logic: files with ALL of the selected tags
      Set<String> fileIds = {};

      for (final tagId in tagIds) {
        final fileTagRecords = await (select(
          fileTags,
        )..where((ft) => ft.tagId.equals(tagId))).get();

        final tagFileIds = fileTagRecords.map((ft) => ft.fileId).toSet();

        if (fileIds.isEmpty) {
          fileIds = tagFileIds;
        } else {
          fileIds = fileIds.intersection(tagFileIds);
        }

        if (fileIds.isEmpty) break;
      }

      if (fileIds.isEmpty) return [];

      return (select(files)
            ..where((f) => f.id.isIn(fileIds.toList()))
            ..orderBy([
              (f) =>
                  OrderingTerm(expression: f.isFolder, mode: OrderingMode.desc),
              (f) => OrderingTerm(expression: f.name),
            ]))
          .get();
    }
  }

  // Chat source preference operations
  Future<List<ChatSourcePreference>> getChatSourcePreferences(String userId) {
    return (select(chatSourcePreferences)
          ..where((csp) => csp.userId.equals(userId))
          ..orderBy([
            (csp) => OrderingTerm(
              expression: csp.selectedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<Set<String>> getSelectedSourceFileIds(String userId) async {
    final prefs = await getChatSourcePreferences(userId);
    return prefs.map((p) => p.fileId).toSet();
  }

  Future<int> saveChatSourcePreference(String userId, String fileId) {
    return into(chatSourcePreferences).insert(
      ChatSourcePreferencesCompanion(
        userId: Value(userId),
        fileId: Value(fileId),
        selectedAt: Value(DateTime.now()),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> saveChatSourcePreferences(
    String userId,
    Set<String> fileIds,
  ) async {
    await batch((batch) {
      // Clear existing preferences for this user
      batch.deleteWhere(
        chatSourcePreferences,
        (csp) => csp.userId.equals(userId),
      );

      // Insert new preferences
      for (final fileId in fileIds) {
        batch.insert(
          chatSourcePreferences,
          ChatSourcePreferencesCompanion(
            userId: Value(userId),
            fileId: Value(fileId),
            selectedAt: Value(DateTime.now()),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<int> removeChatSourcePreference(String userId, String fileId) {
    return (delete(chatSourcePreferences)..where(
          (csp) => csp.userId.equals(userId) & csp.fileId.equals(fileId),
        ))
        .go();
  }

  Future<int> clearChatSourcePreferences(String userId) {
    return (delete(
      chatSourcePreferences,
    )..where((csp) => csp.userId.equals(userId))).go();
  }

  // Chat conversation operations
  Future<List<ChatConversation>> getChatConversations(String userId) {
    return (select(chatConversations)
          ..where((cc) => cc.userId.equals(userId))
          ..orderBy([
            (cc) =>
                OrderingTerm(expression: cc.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<ChatConversation?> getChatConversation(String conversationId) {
    return (select(
      chatConversations,
    )..where((cc) => cc.id.equals(conversationId))).getSingleOrNull();
  }

  Future<int> insertChatConversation(ChatConversationsCompanion conversation) {
    return into(
      chatConversations,
    ).insert(conversation, mode: InsertMode.insertOrReplace);
  }

  Future<int> updateChatConversation(ChatConversationsCompanion conversation) {
    return (update(
      chatConversations,
    )..where((cc) => cc.id.equals(conversation.id.value))).write(conversation);
  }

  Future<int> deleteChatConversation(String conversationId) async {
    // Delete all messages in the conversation first
    await (delete(
      chatMessages,
    )..where((cm) => cm.conversationId.equals(conversationId))).go();

    // Then delete the conversation
    return (delete(
      chatConversations,
    )..where((cc) => cc.id.equals(conversationId))).go();
  }

  // Chat message operations
  Future<List<ChatMessage>> getChatMessages(String conversationId) {
    return (select(chatMessages)
          ..where((cm) => cm.conversationId.equals(conversationId))
          ..orderBy([
            (cm) =>
                OrderingTerm(expression: cm.timestamp, mode: OrderingMode.asc),
            (cm) => OrderingTerm(expression: cm.id, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<int> insertChatMessage(ChatMessagesCompanion message) {
    return into(chatMessages).insert(message, mode: InsertMode.insertOrReplace);
  }

  Future<int> deleteChatMessage(String messageId) {
    return (delete(chatMessages)..where((cm) => cm.id.equals(messageId))).go();
  }

  Future<int> deleteChatMessagesByConversation(String conversationId) {
    return (delete(
      chatMessages,
    )..where((cm) => cm.conversationId.equals(conversationId))).go();
  }
}

/// Open database connection with platform-specific implementation
QueryExecutor _openConnection() {
  if (kIsWeb) {
    // Web platform
    return driftDatabase(
      name: 'scholarmate_cache',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  } else {
    // Native platforms (Android, iOS, Windows, Linux, macOS)
    // Use driftDatabase with native configuration for better Windows support
    return driftDatabase(
      name: 'scholarmate_cache',
      native: DriftNativeOptions(
        databasePath: _getDatabasePathSync,
      ),
    );
  }
}

/// Get database path synchronously for native platforms
Future<String> _getDatabasePathSync() async {
  final dbFolder = await getApplicationDocumentsDirectory();
  return p.join(dbFolder.path, 'scholarmate_cache.db');
}
