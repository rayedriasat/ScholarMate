import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'auth_service.dart';

const _uuid = Uuid();

/// Service for managing Notebook Studio workspaces
class NotebookService extends ChangeNotifier {
  final AppDatabase database;
  final ApiService apiService;
  final AuthService authService;

  NotebookService({
    required this.database,
    required this.apiService,
    required this.authService,
  });

  User? get currentUser => authService.currentUser;
  String get userId => currentUser?.id ?? '';

  // Folder operations
  Future<NotebookFolder> createFolder({
    required String name,
    String? description,
  }) async {
    final folderId = _uuid.v4();
    final now = DateTime.now();

    final companion = NotebookFoldersCompanion.insert(
      id: folderId,
      userId: userId,
      name: name,
      description: Value(description),
      createdAt: now,
      updatedAt: now,
      fileCount: const Value(0),
      isSynced: const Value(false),
    );

    await database.insertNotebookFolder(companion);
    notifyListeners();

    final folder = await database.getNotebookFolder(folderId);
    return folder!;
  }

  Future<void> updateFolder({
    required String folderId,
    String? name,
    String? description,
  }) async {
    final companion = NotebookFoldersCompanion(
      id: Value(folderId),
      name: name != null ? Value(name) : const Value.absent(),
      description: description != null
          ? Value(description)
          : const Value.absent(),
      updatedAt: Value(DateTime.now()),
      isSynced: const Value(false),
    );

    await database.updateNotebookFolder(companion);
    notifyListeners();
  }

  Future<void> deleteFolder(String folderId) async {
    await database.deleteNotebookFolder(folderId);
    notifyListeners();
  }

  Future<List<NotebookFolder>> getFolders() async {
    return database.getNotebookFolders(userId);
  }

  Future<NotebookFolder?> getFolder(String folderId) async {
    return database.getNotebookFolder(folderId);
  }

  // File operations
  Future<NotebookFile> addFile({
    required String folderId,
    required String name,
    required String fileType,
    String? driveFileId,
    String? content,
    int? size,
  }) async {
    final fileId = _uuid.v4();
    final now = DateTime.now();

    final companion = NotebookFilesCompanion.insert(
      id: fileId,
      folderId: folderId,
      userId: userId,
      name: name,
      fileType: fileType,
      driveFileId: Value(driveFileId),
      content: Value(content),
      size: Value(size),
      createdAt: now,
      updatedAt: now,
      isSynced: const Value(false),
    );

    await database.insertNotebookFile(companion);

    // Update folder file count
    await _updateFolderFileCount(folderId);
    notifyListeners();

    final file = await database.getNotebookFile(fileId);
    return file!;
  }

  Future<void> updateFile({
    required String fileId,
    String? name,
    String? content,
  }) async {
    final companion = NotebookFilesCompanion(
      id: Value(fileId),
      name: name != null ? Value(name) : const Value.absent(),
      content: content != null ? Value(content) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
      isSynced: const Value(false),
    );

    await database.updateNotebookFile(companion);
    notifyListeners();
  }

  Future<void> deleteFile(String fileId) async {
    final file = await database.getNotebookFile(fileId);
    if (file != null) {
      await database.deleteNotebookFile(fileId);
      await _updateFolderFileCount(file.folderId);
      notifyListeners();
    }
  }

  Future<List<NotebookFile>> getFiles(String folderId) async {
    return database.getNotebookFiles(folderId);
  }

  Future<NotebookFile?> getFile(String fileId) async {
    return database.getNotebookFile(fileId);
  }

  Future<void> _updateFolderFileCount(String folderId) async {
    final files = await database.getNotebookFiles(folderId);
    await database.updateNotebookFolder(
      NotebookFoldersCompanion(
        id: Value(folderId),
        fileCount: Value(files.length),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // Chat operations
  Future<NotebookChat> createChat({
    required String folderId,
    required String title,
  }) async {
    final chatId = _uuid.v4();
    final now = DateTime.now();

    final companion = NotebookChatsCompanion.insert(
      id: chatId,
      folderId: folderId,
      userId: userId,
      title: title,
      createdAt: now,
      updatedAt: now,
      isSynced: const Value(false),
    );

    await database.insertNotebookChat(companion);
    notifyListeners();

    final chat = await database.getNotebookChat(chatId);
    return chat!;
  }

  Future<void> updateChat({required String chatId, String? title}) async {
    final companion = NotebookChatsCompanion(
      id: Value(chatId),
      title: title != null ? Value(title) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
      isSynced: const Value(false),
    );

    await database.updateNotebookChat(companion);
    notifyListeners();
  }

  Future<void> deleteChat(String chatId) async {
    await database.deleteNotebookChat(chatId);
    notifyListeners();
  }

  Future<List<NotebookChat>> getChats(String folderId) async {
    return database.getNotebookChats(folderId);
  }

  Future<NotebookChat?> getChat(String chatId) async {
    return database.getNotebookChat(chatId);
  }

  // Chat message operations
  Future<NotebookChatMessage> addMessage({
    required String chatId,
    required String content,
    required bool isUser,
    String? citations,
  }) async {
    final messageId = _uuid.v4();

    final companion = NotebookChatMessagesCompanion.insert(
      id: messageId,
      chatId: chatId,
      userId: userId,
      content: content,
      isUser: isUser,
      timestamp: DateTime.now(),
      citations: Value(citations),
      isSynced: const Value(false),
    );

    await database.insertNotebookChatMessage(companion);

    // Update chat's updatedAt
    final chat = await database.getNotebookChat(chatId);
    if (chat != null) {
      await database.updateNotebookChat(
        NotebookChatsCompanion(
          id: Value(chatId),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }

    notifyListeners();

    final messages = await database.getNotebookChatMessages(chatId);
    return messages.firstWhere((m) => m.id == messageId);
  }

  Future<List<NotebookChatMessage>> getMessages(String chatId) async {
    return database.getNotebookChatMessages(chatId);
  }

  Future<void> deleteMessage(String messageId) async {
    await database.deleteNotebookChatMessage(messageId);
    notifyListeners();
  }

  // AI Studio operations
  Future<NotebookAiOutput> generateQuiz({
    required String folderId,
    required String title,
    required List<Map<String, dynamic>> questions,
  }) async {
    final outputId = _uuid.v4();
    final now = DateTime.now();

    final companion = NotebookAiOutputsCompanion.insert(
      id: outputId,
      folderId: folderId,
      userId: userId,
      toolType: 'quiz',
      title: title,
      content: jsonEncode(questions),
      createdAt: now,
      updatedAt: now,
      isSynced: const Value(false),
    );

    await database.insertNotebookAiOutput(companion);
    notifyListeners();

    final output = await database.getNotebookAiOutput(outputId);
    return output!;
  }

  Future<NotebookAiOutput> generateSummary({
    required String folderId,
    required String title,
    required String summary,
  }) async {
    final outputId = _uuid.v4();
    final now = DateTime.now();

    final companion = NotebookAiOutputsCompanion.insert(
      id: outputId,
      folderId: folderId,
      userId: userId,
      toolType: 'summary',
      title: title,
      content: summary,
      createdAt: now,
      updatedAt: now,
      isSynced: const Value(false),
    );

    await database.insertNotebookAiOutput(companion);
    notifyListeners();

    final output = await database.getNotebookAiOutput(outputId);
    return output!;
  }

  Future<NotebookAiOutput> generateMindMap({
    required String folderId,
    required String title,
    required Map<String, dynamic> mindMapData,
  }) async {
    final outputId = _uuid.v4();
    final now = DateTime.now();

    final companion = NotebookAiOutputsCompanion.insert(
      id: outputId,
      folderId: folderId,
      userId: userId,
      toolType: 'mindmap',
      title: title,
      content: jsonEncode(mindMapData),
      createdAt: now,
      updatedAt: now,
      isSynced: const Value(false),
    );

    await database.insertNotebookAiOutput(companion);
    notifyListeners();

    final output = await database.getNotebookAiOutput(outputId);
    return output!;
  }

  Future<NotebookAiOutput> generateFlashcards({
    required String folderId,
    required String title,
    required List<Map<String, dynamic>> flashcards,
  }) async {
    final outputId = _uuid.v4();
    final now = DateTime.now();

    final companion = NotebookAiOutputsCompanion.insert(
      id: outputId,
      folderId: folderId,
      userId: userId,
      toolType: 'flashcard',
      title: title,
      content: jsonEncode(flashcards),
      createdAt: now,
      updatedAt: now,
      isSynced: const Value(false),
    );

    await database.insertNotebookAiOutput(companion);
    notifyListeners();

    final output = await database.getNotebookAiOutput(outputId);
    return output!;
  }

  Future<NotebookAiOutput> generateAudioReview({
    required String folderId,
    required String title,
    required List<Map<String, dynamic>> segments,
  }) async {
    final outputId = _uuid.v4();
    final now = DateTime.now();

    final content = jsonEncode({'segments': segments, 'title': title});

    final companion = NotebookAiOutputsCompanion.insert(
      id: outputId,
      folderId: folderId,
      userId: userId,
      toolType: 'audio',
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      isSynced: const Value(false),
    );

    await database.insertNotebookAiOutput(companion);
    notifyListeners();

    final output = await database.getNotebookAiOutput(outputId);
    return output!;
  }

  Future<List<NotebookAiOutput>> getAiOutputs(
    String folderId, {
    String? toolType,
  }) async {
    return database.getNotebookAiOutputs(folderId, toolType: toolType);
  }

  Future<NotebookAiOutput?> getAiOutput(String outputId) async {
    return database.getNotebookAiOutput(outputId);
  }

  Future<void> deleteAiOutput(String outputId) async {
    await database.deleteNotebookAiOutput(outputId);
    notifyListeners();
  }
}
