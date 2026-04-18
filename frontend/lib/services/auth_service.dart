import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import 'api/api_service.dart';
import 'token_storage.dart';

class AuthService {
  final TokenStorage _tokenStorage;
  final ApiService _apiService;
  final AppConfig _config;

  User? _currentUser;

  AuthService({
    required TokenStorage tokenStorage,
    required ApiService apiService,
    required AppConfig config,
  })  : _tokenStorage = tokenStorage,
        _apiService = apiService,
        _config = config;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> initialize() async {
    try {
      debugPrint('🔄 AuthService: Initializing...');
      final hasTokens = await _tokenStorage.hasValidTokens();
      debugPrint('🔑 Has valid tokens: $hasTokens');

      if (hasTokens) {
        final accessToken = await _tokenStorage.getAccessToken();
        debugPrint('🔐 Access token: ${accessToken?.substring(0, 20)}...');

        try {
          final user = await _apiService.getMe();
          _currentUser = user;
          debugPrint(
              '✅ AuthService: User loaded - ${user.fullName} (${user.roleString})');
          return true;
        } catch (e) {
          debugPrint('❌ AuthService: Failed to get user with stored token: $e');
          await _tokenStorage.clearTokens();
          _currentUser = null;
          return false;
        }
      }
    } catch (e) {
      debugPrint('❌ AuthService: Initialization error: $e');
      await _tokenStorage.clearTokens();
      _currentUser = null;
    }
    return false;
  }

  Future<AuthResult> login(String login, String password) async {
    try {
      debugPrint('🔄 AuthService: Logging in as $login...');
      final response = await _apiService.login(login, password);

      debugPrint('✅ AuthService: Login successful');
      debugPrint(
          '   Access token: ${response.accessToken.substring(0, 20)}...');
      debugPrint(
          '   User: ${response.user.fullName} (${response.user.roleString})');

      // Сохраняем токены
      await _tokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      debugPrint('💾 Tokens saved to secure storage');

      _currentUser = response.user;

      return AuthResult.success(response.user);
    } catch (e) {
      debugPrint('❌ AuthService: Login failed: $e');
      return AuthResult.failure(_getErrorMessage(e));
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('🔄 AuthService: Logging out...');
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken != null) {
        try {
          await _apiService.logout(refreshToken);
          debugPrint('✅ AuthService: Server logout successful');
        } catch (e) {
          debugPrint('⚠️ AuthService: Server logout failed: $e');
        }
      }
    } catch (e) {
      debugPrint('⚠️ AuthService: Logout error: $e');
    } finally {
      await _tokenStorage.clearTokens();
      _currentUser = null;
      debugPrint('🧹 Tokens cleared');
    }
  }

  Future<bool> refreshTokenIfNeeded() async {
    // Токен обновляется автоматически в ApiClient при 401
    return true;
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      await _apiService.changePassword(oldPassword, newPassword);
      return true;
    } catch (e) {
      debugPrint('❌ AuthService: Change password failed: $e');
      return false;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is Map && error.containsKey('message')) return error['message'];
    if (error.toString().contains('401')) return 'Неверный логин или пароль';
    if (error.toString().contains('SocketException'))
      return 'Не удалось подключиться к серверу';
    return 'Ошибка авторизации: $error';
  }
}

class AuthResult {
  final bool success;
  final User? user;
  final String? errorMessage;

  AuthResult.success(this.user)
      : success = true,
        errorMessage = null;
  AuthResult.failure(this.errorMessage)
      : success = false,
        user = null;
}
