enum UserRole { admin, expert, team, public }

class User {
  final String id;
  final String login;
  final String fullName;
  final String? email;
  final String? phone;
  final UserRole role;
  final String? teamId;
  final bool isActive;
  final DateTime? lastLoginAt;

  User({
    required this.id,
    required this.login,
    required this.fullName,
    this.email,
    this.phone,
    required this.role,
    this.teamId,
    required this.isActive,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      login: json['login'],
      fullName: json['full_name'],
      email: json['email'],
      phone: json['phone'],
      role: _parseRole(json['role']),
      teamId: json['team_id'],
      isActive: json['is_active'] ?? true,
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.parse(json['last_login_at'])
          : null,
    );
  }

  static UserRole _parseRole(String role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'expert':
        return UserRole.expert;
      case 'team':
        return UserRole.team;
      default:
        return UserRole.public;
    }
  }

  String get roleString {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.expert:
        return 'expert';
      case UserRole.team:
        return 'team';
      case UserRole.public:
        return 'public';
    }
  }
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final User user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      user: User.fromJson(json['user']),
    );
  }
}
