/// API Key models for frontend
class ApiKeyModel {
  final String id;
  final String provider;
  final bool isActive;
  final bool isValidated;
  final String? validationError;
  final DateTime? lastValidatedAt;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String maskedKey;

  ApiKeyModel({
    required this.id,
    required this.provider,
    required this.isActive,
    required this.isValidated,
    this.validationError,
    this.lastValidatedAt,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    required this.maskedKey,
  });

  factory ApiKeyModel.fromJson(Map<String, dynamic> json) {
    return ApiKeyModel(
      id: json['id'],
      provider: json['provider'],
      isActive: json['is_active'],
      isValidated: json['is_validated'],
      validationError: json['validation_error'],
      lastValidatedAt: json['last_validated_at'] != null
          ? DateTime.parse(json['last_validated_at'])
          : null,
      priority: json['priority'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      maskedKey: json['masked_key'],
    );
  }
}

class ProviderConfig {
  final String name;
  final String displayName;
  final bool supportsChat;
  final bool supportsEmbeddings;
  final String? defaultChatModel;
  final String? defaultEmbeddingModel;
  final String apiKeyFormat;
  final String docsUrl;

  ProviderConfig({
    required this.name,
    required this.displayName,
    required this.supportsChat,
    required this.supportsEmbeddings,
    this.defaultChatModel,
    this.defaultEmbeddingModel,
    required this.apiKeyFormat,
    required this.docsUrl,
  });

  factory ProviderConfig.fromJson(Map<String, dynamic> json) {
    return ProviderConfig(
      name: json['name'],
      displayName: json['display_name'],
      supportsChat: json['supports_chat'],
      supportsEmbeddings: json['supports_embeddings'],
      defaultChatModel: json['default_chat_model'],
      defaultEmbeddingModel: json['default_embedding_model'],
      apiKeyFormat: json['api_key_format'],
      docsUrl: json['docs_url'],
    );
  }
}

class UsageStats {
  final String provider;
  final int totalRequests;
  final int totalTokens;
  final double totalCost;
  final double successRate;

  UsageStats({
    required this.provider,
    required this.totalRequests,
    required this.totalTokens,
    required this.totalCost,
    required this.successRate,
  });

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    return UsageStats(
      provider: json['provider'],
      totalRequests: json['total_requests'],
      totalTokens: json['total_tokens'],
      totalCost: (json['total_cost'] as num).toDouble(),
      successRate: (json['success_rate'] as num).toDouble(),
    );
  }
}
