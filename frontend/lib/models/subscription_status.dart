/// Model representing a user's subscription status
class SubscriptionStatus {
  final String plan; // 'free' or 'premium'
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final bool isActive;

  SubscriptionStatus({
    required this.plan,
    this.activatedAt,
    this.expiresAt,
    required this.isActive,
  });

  /// Create from JSON response
  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      plan: json['plan'] as String,
      activatedAt: json['activated_at'] != null
          ? DateTime.parse(json['activated_at'])
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      isActive: json['is_active'] as bool,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'plan': plan,
      'activated_at': activatedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  /// Check if user has premium subscription
  bool get isPremium => plan == 'premium' && isActive;

  /// Check if user is on free plan
  bool get isFree => plan == 'free' || !isActive;

  @override
  String toString() {
    return 'SubscriptionStatus(plan: $plan, isActive: $isActive, '
        'activatedAt: $activatedAt, expiresAt: $expiresAt)';
  }
}
