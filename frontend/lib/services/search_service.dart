import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'config_service.dart';
import 'auth_service.dart';

/// Search result item
class SearchResultItem {
  final String fileId;
  final String fileName;
  final String matchType; // 'exact', 'partial', 'semantic', 'fuzzy'
  final double relevanceScore;
  final String snippet;
  final int? pageNumber;
  final String? matchContext; // 'filename' or 'content'
  final int? fileSize;
  final String? modifiedTime;
  final String? mimeType;

  SearchResultItem({
    required this.fileId,
    required this.fileName,
    required this.matchType,
    required this.relevanceScore,
    this.snippet = '',
    this.pageNumber,
    this.matchContext,
    this.fileSize,
    this.modifiedTime,
    this.mimeType,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    return SearchResultItem(
      fileId: json['file_id'] as String,
      fileName: json['file_name'] as String,
      matchType: json['match_type'] as String,
      relevanceScore: (json['relevance_score'] as num).toDouble(),
      snippet: json['snippet'] as String? ?? '',
      pageNumber: json['page_number'] as int?,
      matchContext: json['match_context'] as String?,
      fileSize: json['file_size'] as int?,
      modifiedTime: json['modified_time'] as String?,
      mimeType: json['mime_type'] as String?,
    );
  }

  String get matchTypeLabel {
    switch (matchType) {
      case 'exact':
        return 'Exact Match';
      case 'partial':
        return 'Partial Match';
      case 'semantic':
        return 'Content Match';
      case 'fuzzy':
        return 'Fuzzy Match';
      default:
        return matchType;
    }
  }

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    final kb = fileSize! / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Search response
class SearchResponse {
  final List<SearchResultItem> results;
  final int totalCount;
  final String query;
  final int searchTimeMs;

  SearchResponse({
    required this.results,
    required this.totalCount,
    required this.query,
    required this.searchTimeMs,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      results: (json['results'] as List)
          .map(
            (item) => SearchResultItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      totalCount: json['total_count'] as int,
      query: json['query'] as String,
      searchTimeMs: json['search_time_ms'] as int,
    );
  }
}

/// Service for advanced search functionality
class SearchService extends ChangeNotifier {
  final ConfigService _configService = ConfigService();
  final AuthService _authService;

  SearchService(this._authService);

  bool _isSearching = false;
  String? _error;
  SearchResponse? _lastSearchResponse;

  bool get isSearching => _isSearching;
  String? get error => _error;
  SearchResponse? get lastSearchResponse => _lastSearchResponse;

  /// Perform advanced search
  Future<SearchResponse> search({
    required String query,
    int maxResults = 20,
    bool includeSemantic = true,
  }) async {
    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${_configService.backendUrl}/api/search/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'user_id': user.id,
          'max_results': maxResults,
          'include_semantic': includeSemantic,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Search failed: ${response.body}');
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      _lastSearchResponse = SearchResponse.fromJson(responseData);
      _isSearching = false;
      notifyListeners();

      return _lastSearchResponse!;
    } catch (e) {
      _error = e.toString();
      _isSearching = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Clear search results
  void clearResults() {
    _lastSearchResponse = null;
    _error = null;
    notifyListeners();
  }
}
