import 'package:dio/dio.dart';
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
      debugPrint('[AUTH] Initializing...');
      final hasTokens = await _tokenStorage.hasValidTokens();
      debugPrint('[AUTH] Has valid tokens: $hasTokens');

      if (hasTokens) {
        final accessToken = await _tokenStorage.getAccessToken();
        debugPrint('[AUTH] Access token: ${accessToken?.substring(0, 20)}...');

        try {
          final user = await _apiService.getMe();
          _currentUser = user;
          debugPrint(
              '[AUTH] User loaded - ${user.fullName} (${user.roleString})');
          return true;
        } catch (e) {
          debugPrint('[AUTH] Failed to get user with stored token: $e');
          await _tokenStorage.clearTokens();
          _currentUser = null;
          return false;
        }
      }
    } catch (e) {
      debugPrint('[AUTH] Initialization error: $e');
      await _tokenStorage.clearTokens();
      _currentUser = null;
    }
    return false;
  }

  Future<AuthResult> login(String login, String password) async {
    try {
      debugPrint('[AUTH] Logging in as $login...');
      final response = await _apiService.login(login, password);

      debugPrint('[AUTH] Login successful');
      debugPrint(
          '[AUTH] Access token: ${response.accessToken.substring(0, 20)}...');
      debugPrint(
          '[AUTH] User: ${response.user.fullName} (${response.user.roleString})');

      await _tokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
      debugPrint('[AUTH] Tokens saved to secure storage');

      _currentUser = response.user;

      return AuthResult.success(response.user);
    } on DioException catch (e) {
      debugPrint('[AUTH] Login failed with DioException: ${e.type}');
      debugPrint('[AUTH] Message: ${e.message}');
      debugPrint('[AUTH] Response: ${e.response?.data}');

      String errorMessage = 'Network error';
      if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Failed to connect to server. Check:\n'
            '1. Backend is running at http://192.168.5.46:8000\n'
            '2. CORS is configured on backend\n'
            '3. No browser blocking';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'Endpoint not found. Check URL: ${e.requestOptions.uri}';
      } else if (e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ??
            e.response?.data['error'] ??
            'Server error';
      }

      return AuthResult.failure(errorMessage);
    } catch (e) {
      debugPrint('[AUTH] Login failed: $e');
      return AuthResult.failure(_getErrorMessage(e));
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('[AUTH] Logging out...');
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken != null) {
        try {
          await _apiService.logout(refreshToken);
          debugPrint('[AUTH] Server logout successful');
        } catch (e) {
          debugPrint('[AUTH] Server logout failed: $e');
        }
      }
    } catch (e) {
      debugPrint('[AUTH] Logout error: $e');
    } finally {
      await _tokenStorage.clearTokens();
      _currentUser = null;
      debugPrint('[AUTH] Tokens cleared');
    }
  }

  Future<bool> refreshTokenIfNeeded() async {
    return true;
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      await _apiService.changePassword(oldPassword, newPassword);
      return true;
    } catch (e) {
      debugPrint('[AUTH] Change password failed: $e');
      return false;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is Map && error.containsKey('message')) return error['message'];
    if (error.toString().contains('401')) return 'Invalid login or password';
    if (error.toString().contains('SocketException'))
      return 'Failed to connect to server';
    return 'Authorization error: $error';
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
