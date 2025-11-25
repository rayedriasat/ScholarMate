import 'dart:io' as io;
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
    NotebookFolders,
    NotebookFiles,
    NotebookChats,
    NotebookChatMessages,
    NotebookAiOutputs,
    ReadingSessions,
    PageReadHistory,
    CachedEmbeddings,
    LocalChatMessages,
    ModelMetadata,
    OfflineAiSyncQueue,
    FileChatThreads,
    FileChatMessages,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Constructor for testing with custom executor
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Create indices for offline AI tables
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_cached_embeddings_file_id ON cached_embeddings(file_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_cached_embeddings_synced ON cached_embeddings(synced);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_local_chat_messages_conversation_id ON local_chat_messages(conversation_id);',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_local_chat_messages_synced ON local_chat_messages(synced);',
        );
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
        if (from < 7) {
          // Migration from version 6 to 7: Add notebook studio tables
          await m.createTable(notebookFolders);
          await m.createTable(notebookFiles);
          await m.createTable(notebookChats);
          await m.createTable(notebookChatMessages);
          await m.createTable(notebookAiOutputs);
        }
        if (from < 8) {
          // Migration from version 7 to 8: Add analytics tables
          await m.createTable(readingSessions);
          await m.createTable(pageReadHistory);
        }
        if (from < 9) {
          // Migration from version 8 to 9: Add offline AI tables
          await m.createTable(cachedEmbeddings);
          await m.createTable(localChatMessages);
          await m.createTable(modelMetadata);
          await m.createTable(offlineAiSyncQueue);

          // Create indices for efficient queries
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_cached_embeddings_file_id ON cached_embeddings(file_id);',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_cached_embeddings_synced ON cached_embeddings(synced);',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_local_chat_messages_conversation_id ON local_chat_messages(conversation_id);',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_local_chat_messages_synced ON local_chat_messages(synced);',
          );
        }
        if (from < 10) {
          // Migration from version 9 to 10: Add file chat tables
          await m.createTable(fileChatThreads);
          await m.createTable(fileChatMessages);

          // Create indices for efficient queries
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_file_chat_messages_file_id ON file_chat_messages(file_id);',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_file_chat_messages_thread_id ON file_chat_messages(thread_id);',
          );
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

  // Notebook folder operations
  Future<List<NotebookFolder>> getNotebookFolders(String userId) {
    return (select(notebookFolders)
          ..where((nf) => nf.userId.equals(userId))
          ..orderBy([
            (nf) =>
                OrderingTerm(expression: nf.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<NotebookFolder?> getNotebookFolder(String folderId) {
    return (select(
      notebookFolders,
    )..where((nf) => nf.id.equals(folderId))).getSingleOrNull();
  }

  Future<int> insertNotebookFolder(NotebookFoldersCompanion folder) {
    return into(
      notebookFolders,
    ).insert(folder, mode: InsertMode.insertOrReplace);
  }

  Future<int> updateNotebookFolder(NotebookFoldersCompanion folder) {
    return (update(
      notebookFolders,
    )..where((nf) => nf.id.equals(folder.id.value))).write(folder);
  }

  Future<int> deleteNotebookFolder(String folderId) async {
    // Delete all related data
    await (delete(
      notebookFiles,
    )..where((nf) => nf.folderId.equals(folderId))).go();
    await (delete(
      notebookChats,
    )..where((nc) => nc.folderId.equals(folderId))).go();
    await (delete(
      notebookAiOutputs,
    )..where((nao) => nao.folderId.equals(folderId))).go();

    return (delete(
      notebookFolders,
    )..where((nf) => nf.id.equals(folderId))).go();
  }

  // Notebook file operations
  Future<List<NotebookFile>> getNotebookFiles(String folderId) {
    return (select(notebookFiles)
          ..where((nf) => nf.folderId.equals(folderId))
          ..orderBy([
            (nf) =>
                OrderingTerm(expression: nf.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<NotebookFile?> getNotebookFile(String fileId) {
    return (select(
      notebookFiles,
    )..where((nf) => nf.id.equals(fileId))).getSingleOrNull();
  }

  Future<int> insertNotebookFile(NotebookFilesCompanion file) {
    return into(notebookFiles).insert(file, mode: InsertMode.insertOrReplace);
  }

  Future<int> updateNotebookFile(NotebookFilesCompanion file) {
    return (update(
      notebookFiles,
    )..where((nf) => nf.id.equals(file.id.value))).write(file);
  }

  Future<int> deleteNotebookFile(String fileId) {
    return (delete(notebookFiles)..where((nf) => nf.id.equals(fileId))).go();
  }

  // Notebook chat operations
  Future<List<NotebookChat>> getNotebookChats(String folderId) {
    return (select(notebookChats)
          ..where((nc) => nc.folderId.equals(folderId))
          ..orderBy([
            (nc) =>
                OrderingTerm(expression: nc.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<NotebookChat?> getNotebookChat(String chatId) {
    return (select(
      notebookChats,
    )..where((nc) => nc.id.equals(chatId))).getSingleOrNull();
  }

  Future<int> insertNotebookChat(NotebookChatsCompanion chat) {
    return into(notebookChats).insert(chat, mode: InsertMode.insertOrReplace);
  }

  Future<int> updateNotebookChat(NotebookChatsCompanion chat) {
    return (update(
      notebookChats,
    )..where((nc) => nc.id.equals(chat.id.value))).write(chat);
  }

  Future<int> deleteNotebookChat(String chatId) async {
    // Delete all messages first
    await (delete(
      notebookChatMessages,
    )..where((ncm) => ncm.chatId.equals(chatId))).go();

    return (delete(notebookChats)..where((nc) => nc.id.equals(chatId))).go();
  }

  // Notebook chat message operations
  Future<List<NotebookChatMessage>> getNotebookChatMessages(String chatId) {
    return (select(notebookChatMessages)
          ..where((ncm) => ncm.chatId.equals(chatId))
          ..orderBy([
            (ncm) =>
                OrderingTerm(expression: ncm.timestamp, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<int> insertNotebookChatMessage(NotebookChatMessagesCompanion message) {
    return into(
      notebookChatMessages,
    ).insert(message, mode: InsertMode.insertOrReplace);
  }

  Future<int> deleteNotebookChatMessage(String messageId) {
    return (delete(
      notebookChatMessages,
    )..where((ncm) => ncm.id.equals(messageId))).go();
  }

  // Notebook AI output operations
  Future<List<NotebookAiOutput>> getNotebookAiOutputs(
    String folderId, {
    String? toolType,
  }) {
    if (toolType != null) {
      return (select(notebookAiOutputs)
            ..where(
              (nao) =>
                  nao.folderId.equals(folderId) & nao.toolType.equals(toolType),
            )
            ..orderBy([
              (nao) => OrderingTerm(
                expression: nao.createdAt,
                mode: OrderingMode.desc,
              ),
            ]))
          .get();
    }
    return (select(notebookAiOutputs)
          ..where((nao) => nao.folderId.equals(folderId))
          ..orderBy([
            (nao) => OrderingTerm(
              expression: nao.createdAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<NotebookAiOutput?> getNotebookAiOutput(String outputId) {
    return (select(
      notebookAiOutputs,
    )..where((nao) => nao.id.equals(outputId))).getSingleOrNull();
  }

  Future<int> insertNotebookAiOutput(NotebookAiOutputsCompanion output) {
    return into(
      notebookAiOutputs,
    ).insert(output, mode: InsertMode.insertOrReplace);
  }

  Future<int> updateNotebookAiOutput(NotebookAiOutputsCompanion output) {
    return (update(
      notebookAiOutputs,
    )..where((nao) => nao.id.equals(output.id.value))).write(output);
  }

  Future<int> deleteNotebookAiOutput(String outputId) {
    return (delete(
      notebookAiOutputs,
    )..where((nao) => nao.id.equals(outputId))).go();
  }

  // Cached embeddings operations
  Future<List<CachedEmbedding>> getCachedEmbeddings(String fileId) {
    return (select(cachedEmbeddings)
          ..where((ce) => ce.fileId.equals(fileId))
          ..orderBy([(ce) => OrderingTerm(expression: ce.chunkIndex)]))
        .get();
  }

  Future<List<CachedEmbedding>> getUnsyncedEmbeddings() {
    return (select(
      cachedEmbeddings,
    )..where((ce) => ce.synced.equals(false))).get();
  }

  Future<int> insertCachedEmbedding(CachedEmbeddingsCompanion embedding) {
    return into(
      cachedEmbeddings,
    ).insert(embedding, mode: InsertMode.insertOrReplace);
  }

  Future<void> insertCachedEmbeddings(
    List<CachedEmbeddingsCompanion> embeddings,
  ) async {
    await batch((batch) {
      batch.insertAll(
        cachedEmbeddings,
        embeddings,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<int> markEmbeddingsSynced(List<String> embeddingIds) async {
    return await (update(
      cachedEmbeddings,
    )..where((ce) => ce.id.isIn(embeddingIds))).write(
      CachedEmbeddingsCompanion(
        synced: const Value(true),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteCachedEmbeddingsByFile(String fileId) {
    return (delete(
      cachedEmbeddings,
    )..where((ce) => ce.fileId.equals(fileId))).go();
  }

  // Local chat messages operations
  Future<List<LocalChatMessage>> getLocalChatMessages(String conversationId) {
    return (select(localChatMessages)
          ..where((lcm) => lcm.conversationId.equals(conversationId))
          ..orderBy([
            (lcm) =>
                OrderingTerm(expression: lcm.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<List<LocalChatMessage>> getUnsyncedChatMessages() {
    return (select(
      localChatMessages,
    )..where((lcm) => lcm.synced.equals(false))).get();
  }

  Future<int> insertLocalChatMessage(LocalChatMessagesCompanion message) {
    return into(
      localChatMessages,
    ).insert(message, mode: InsertMode.insertOrReplace);
  }

  Future<int> markChatMessagesSynced(List<String> messageIds) async {
    return await (update(
      localChatMessages,
    )..where((lcm) => lcm.id.isIn(messageIds))).write(
      LocalChatMessagesCompanion(
        synced: const Value(true),
        syncedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteLocalChatMessage(String messageId) {
    return (delete(
      localChatMessages,
    )..where((lcm) => lcm.id.equals(messageId))).go();
  }

  Future<int> deleteLocalChatMessagesByConversation(String conversationId) {
    return (delete(
      localChatMessages,
    )..where((lcm) => lcm.conversationId.equals(conversationId))).go();
  }

  // Model metadata operations
  Future<List<ModelMetadataData>> getInstalledModels() {
    return (select(modelMetadata)..orderBy([
          (mm) =>
              OrderingTerm(expression: mm.installedAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Future<List<ModelMetadataData>> getModelsByType(String type) {
    return (select(modelMetadata)
          ..where((mm) => mm.type.equals(type))
          ..orderBy([
            (mm) => OrderingTerm(
              expression: mm.installedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<ModelMetadataData?> getModel(String modelId) {
    return (select(
      modelMetadata,
    )..where((mm) => mm.id.equals(modelId))).getSingleOrNull();
  }

  Future<int> insertModel(ModelMetadataCompanion model) {
    return into(modelMetadata).insert(model, mode: InsertMode.insertOrReplace);
  }

  Future<int> deleteModel(String modelId) {
    return (delete(modelMetadata)..where((mm) => mm.id.equals(modelId))).go();
  }

  // Offline AI sync queue operations
  Future<List<OfflineAiSyncQueueData>> getPendingAiSyncOperations() {
    return (select(
      offlineAiSyncQueue,
    )..orderBy([(oasq) => OrderingTerm(expression: oasq.createdAt)])).get();
  }

  Future<List<OfflineAiSyncQueueData>> getAiSyncOperationsByType(
    String operationType,
  ) {
    return (select(offlineAiSyncQueue)
          ..where((oasq) => oasq.operationType.equals(operationType))
          ..orderBy([(oasq) => OrderingTerm(expression: oasq.createdAt)]))
        .get();
  }

  Future<int> insertAiSyncOperation(OfflineAiSyncQueueCompanion operation) {
    return into(offlineAiSyncQueue).insert(operation);
  }

  Future<int> updateAiSyncOperation(OfflineAiSyncQueueCompanion operation) {
    return (update(
      offlineAiSyncQueue,
    )..where((oasq) => oasq.id.equals(operation.id.value))).write(operation);
  }

  Future<int> deleteAiSyncOperation(String operationId) {
    return (delete(
      offlineAiSyncQueue,
    )..where((oasq) => oasq.id.equals(operationId))).go();
  }

  Future<int> deleteAiSyncOperationsByType(String operationType) {
    return (delete(
      offlineAiSyncQueue,
    )..where((oasq) => oasq.operationType.equals(operationType))).go();
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
    // Use driftDatabase with native configuration
    return driftDatabase(
      name: 'scholarmate_cache',
      native: DriftNativeOptions(
        databasePath: () async {
          print('🔵 Starting database path resolution...');

          try {
            // Use ApplicationSupport directory instead of Documents
            // This avoids OneDrive sync issues on Windows
            final dbFolder = await getApplicationSupportDirectory();
            print('🔵 Got app support directory: ${dbFolder.path}');

            // Ensure the directory exists
            final directory = io.Directory(dbFolder.path);
            if (!await directory.exists()) {
              print('🔵 Creating directory: ${directory.path}');
              await directory.create(recursive: true);
              print('🔵 Directory created successfully');
            }

            final dbPath = p.join(dbFolder.path, 'scholarmate_cache.db');
            print('🟢 Database path resolved: $dbPath');

            return dbPath;
          } catch (e, stackTrace) {
            // If there's any error, fall back to temp directory
            print('🔴 Error getting app support directory: $e');
            print('🔴 Stack trace: $stackTrace');

            final tempDir = io.Directory.systemTemp;
            final fallbackPath = p.join(tempDir.path, 'scholarmate_cache.db');
            print('🟡 Using fallback database path: $fallbackPath');

            return fallbackPath;
          }
        },
      ),
    );
  }
}
