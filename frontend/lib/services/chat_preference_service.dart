import '../database/database.dart';

/// Service for managing chat source selection preferences
class ChatPreferenceService {
  final AppDatabase _database;

  ChatPreferenceService(this._database);

  /// Load previously selected source file IDs for a user
  Future<Set<String>> loadSelectedSources(String userId) async {
    try {
      return await _database.getSelectedSourceFileIds(userId);
    } catch (e) {
      print('Error loading chat source preferences: $e');
      return {};
    }
  }

  /// Save selected source file IDs for a user
  Future<void> saveSelectedSources(String userId, Set<String> fileIds) async {
    try {
      await _database.saveChatSourcePreferences(userId, fileIds);
    } catch (e) {
      print('Error saving chat source preferences: $e');
    }
  }

  /// Add a single source to preferences
  Future<void> addSource(String userId, String fileId) async {
    try {
      await _database.saveChatSourcePreference(userId, fileId);
    } catch (e) {
      print('Error adding chat source preference: $e');
    }
  }

  /// Remove a single source from preferences
  Future<void> removeSource(String userId, String fileId) async {
    try {
      await _database.removeChatSourcePreference(userId, fileId);
    } catch (e) {
      print('Error removing chat source preference: $e');
    }
  }

  /// Clear all source preferences for a user
  Future<void> clearAllSources(String userId) async {
    try {
      await _database.clearChatSourcePreferences(userId);
    } catch (e) {
      print('Error clearing chat source preferences: $e');
    }
  }

  /// Select all available sources for a user
  Future<void> selectAllSources(String userId, List<String> fileIds) async {
    try {
      await _database.saveChatSourcePreferences(userId, fileIds.toSet());
    } catch (e) {
      print('Error selecting all sources: $e');
    }
  }
}
