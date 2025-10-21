/// User model representing an authenticated user
class User {
  final String id; // Google sub claim
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? accessToken;
  final String? idToken;

  User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.accessToken,
    this.idToken,
  });

  /// Create User from Google Sign-In account data
  factory User.fromGoogleSignIn({
    required String id,
    required String email,
    String? displayName,
    String? photoUrl,
    String? accessToken,
    String? idToken,
  }) {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      accessToken: accessToken,
      idToken: idToken,
    );
  }

  /// Create a copy of the user with updated fields
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? accessToken,
    String? idToken,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      accessToken: accessToken ?? this.accessToken,
      idToken: idToken ?? this.idToken,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'accessToken': accessToken,
      'idToken': idToken,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      accessToken: json['accessToken'] as String?,
      idToken: json['idToken'] as String?,
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
