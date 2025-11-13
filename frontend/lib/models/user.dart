/// User model representing an authenticated user
class User {
  final String id; // Google sub claim
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? accessToken;
  final String? refreshToken;
  final String? idToken;
  final DateTime? tokenExpiry;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.accessToken,
    this.refreshToken,
    this.idToken,
    this.tokenExpiry,
  });

  /// Create User from Google Sign-In account data
  factory User.fromGoogleSignIn({
    required String id,
    required String email,
    String? displayName,
    String? photoUrl,
    String? accessToken,
    String? refreshToken,
    String? idToken,
    DateTime? tokenExpiry,
  }) {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      accessToken: accessToken,
      refreshToken: refreshToken,
      idToken: idToken,
      tokenExpiry: tokenExpiry,
    );
  }

  /// Create a copy of the user with updated fields
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? accessToken,
    String? refreshToken,
    String? idToken,
    DateTime? tokenExpiry,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      idToken: idToken ?? this.idToken,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'idToken': idToken,
      'tokenExpiry': tokenExpiry?.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      idToken: json['idToken'] as String?,
      tokenExpiry: json['tokenExpiry'] != null
          ? DateTime.parse(json['tokenExpiry'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id && other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}
