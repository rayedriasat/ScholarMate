import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../database/database.dart';
import '../models/chat_message.dart' as model;
import 'package:drift/drift.dart';

/// Service for managing chat history and conversations
class ChatHistoryService {
  final AppDatabase _database;

  ChatHistoryService(this._database);

  /// Create a new conversation
  Future<String> createConversation({
    required String userId,
    required String title,
    required Set<String> selectedSourceIds,
  }) async {
    final conversationId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();

    await _database.insertChatConversation(
      ChatConversationsCompanion(
        id: Value(conversationId),
        userId: Value(userId),
        title: Value(title),
        createdAt: Value(now),
        updatedAt: Value(now),
        selectedSourceIds: Value(jsonEncode(selectedSourceIds.toList())),
      ),
    );

    return conversationId;
  }

  /// Get all conversations for a user
  Future<List<ChatConversation>> getConversations(String userId) async {
    return await _database.getChatConversations(userId);
  }

  /// Get a specific conversation
  Future<ChatConversation?> getConversation(String conversationId) async {
    return await _database.getChatConversation(conversationId);
  }

  /// Update conversation title
  Future<void> updateConversationTitle(
    String conversationId,
    String newTitle,
  ) async {
    await _database.updateChatConversation(
      ChatConversationsCompanion(
        id: Value(conversationId),
        title: Value(newTitle),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Update conversation timestamp (when new message is added)
  Future<void> updateConversationTimestamp(String conversationId) async {
    await _database.updateChatConversation(
      ChatConversationsCompanion(
        id: Value(conversationId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Delete a conversation and all its messages
  Future<void> deleteConversation(String conversationId) async {
    await _database.deleteChatConversation(conversationId);
  }

  /// Save a message to a conversation
  Future<void> saveMessage({
    required String conversationId,
    required model.ChatMessage message,
  }) async {
    String? citationsJson;
    if (message.citations != null && message.citations!.isNotEmpty) {
      citationsJson = jsonEncode(
        message.citations!.map((c) => c.toJson()).toList(),
      );
    }

    await _database.insertChatMessage(
      ChatMessagesCompanion(
        id: Value(message.id),
        conversationId: Value(conversationId),
        content: Value(message.content),
        isUser: Value(message.isUser),
        timestamp: Value(message.timestamp),
        citations: Value(citationsJson),
      ),
    );

    // Update conversation timestamp
    await updateConversationTimestamp(conversationId);
  }

  /// Load messages for a conversation
  Future<List<model.ChatMessage>> loadMessages(String conversationId) async {
    final dbMessages = await _database.getChatMessages(conversationId);
    
    return dbMessages.map((dbMsg) {
      List<model.Citation>? citations;
      if (dbMsg.citations != null) {
        try {
          final citationsList = jsonDecode(dbMsg.citations!) as List;
          citations = citationsList
              .map((c) => model.Citation.fromJson(c as Map<String, dynamic>))
              .toList();
        } catch (e) {
          debugPrint('Failed to parse citations: $e');
        }
      }

      return model.ChatMessage(
        id: dbMsg.id,
        content: dbMsg.content,
        isUser: dbMsg.isUser,
        timestamp: dbMsg.timestamp,
        citations: citations,
      );
    }).toList();
  }

  /// Get selected source IDs for a conversation
  Future<Set<String>> getConversationSourceIds(String conversationId) async {
    final conversation = await getConversation(conversationId);
    if (conversation == null) return {};

    try {
      final sourceList = jsonDecode(conversation.selectedSourceIds) as List;
      return sourceList.cast<String>().toSet();
    } catch (e) {
      debugPrint('Failed to parse source IDs: $e');
      return {};
    }
  }

  /// Update selected sources for a conversation
  Future<void> updateConversationSources(
    String conversationId,
    Set<String> selectedSourceIds,
  ) async {
    await _database.updateChatConversation(
      ChatConversationsCompanion(
        id: Value(conversationId),
        selectedSourceIds: Value(jsonEncode(selectedSourceIds.toList())),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Generate a title from the first user message
  String generateTitle(String firstMessage) {
    // Take first 50 characters or until first newline
    final title = firstMessage.split('\n').first;
    if (title.length > 50) {
      return '${title.substring(0, 47)}...';
    }
    return title;
  }

  /// Clear all conversations for a user
  Future<void> clearAllConversations(String userId) async {
    final conversations = await getConversations(userId);
    for (final conversation in conversations) {
      await deleteConversation(conversation.id);
    }
  }
}
