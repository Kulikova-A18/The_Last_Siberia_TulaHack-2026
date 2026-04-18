import 'api_client.dart';
import '../../models/user.dart';

/// API для авторизации
class AuthApi {
  final ApiClient _client;

  AuthApi(this._client);

  /// POST /auth/login
  Future<AuthResponse> login(String login, String password) async {
    final response = await _client.post(
      '/auth/login',
      data: {
        'login': login,
        'password': password,
      },
    );
    return AuthResponse.fromJson(response.data);
  }

  /// POST /auth/refresh
  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final response = await _client.post(
      '/auth/refresh',
      data: {
        'refresh_token': refreshToken,
      },
    );
    return response.data;
  }

  /// POST /auth/logout
  Future<void> logout(String refreshToken) async {
    await _client.post(
      '/auth/logout',
      data: {
        'refresh_token': refreshToken,
      },
    );
  }

  /// GET /auth/me
  Future<User> getMe() async {
    final response = await _client.get('/auth/me');
    return User.fromJson(response.data);
  }

  /// POST /auth/change-password
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _client.post(
      '/auth/change-password',
      data: {
        'old_password': oldPassword,
        'new_password': newPassword,
      },
    );
  }
}
