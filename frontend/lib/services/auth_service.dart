import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import 'api/auth_api.dart';
import 'token_storage.dart';

/// Сервис авторизации - управляет состоянием пользователя и токенами
class AuthService {
  final TokenStorage _tokenStorage;
  final AuthApi _authApi;
  final AppConfig _config;

  User? _currentUser;

  AuthService({
    required TokenStorage tokenStorage,
    required AuthApi authApi,
    required AppConfig config,
  })  : _tokenStorage = tokenStorage,
        _authApi = authApi,
        _config = config;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// Инициализация - проверка существующих токенов
  Future<bool> initialize() async {
    try {
      if (await _tokenStorage.hasValidTokens()) {
        // Пробуем получить данные пользователя
        final user = await _authApi.getMe();
        _currentUser = user;
        return true;
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      await logout();
    }
    return false;
  }

  /// Вход в систему
  Future<AuthResult> login(String login, String password) async {
    try {
      // Проверяем демо-режим
      if (_config.mockEnabled) {
        return await _mockLogin(login, password);
      }

      final response = await _authApi.login(login, password);

      await _tokenStorage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );

      _currentUser = response.user;

      return AuthResult.success(response.user);
    } catch (e) {
      return AuthResult.failure(_getErrorMessage(e));
    }
  }

  /// Демо-вход для разработки
  Future<AuthResult> _mockLogin(String login, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));

    UserRole role;
    String cleanLogin = login.toLowerCase().trim();

    if (cleanLogin == 'admin') {
      role = UserRole.admin;
    } else if (cleanLogin == 'expert') {
      role = UserRole.expert;
    } else if (cleanLogin == 'team') {
      role = UserRole.team;
    } else {
      return AuthResult.failure(
          'Неверный логин или пароль. Используйте admin, expert или team');
    }

    _currentUser = User(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      login: login,
      fullName: _getMockFullName(login, role),
      email: '$login@hackrank.local',
      role: role,
      teamId: role == UserRole.team ? 'mock-team-id' : null,
      isActive: true,
      lastLoginAt: DateTime.now(),
    );

    // Сохраняем мок-токены
    await _tokenStorage.saveTokens(
      accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken:
          'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
    );

    return AuthResult.success(_currentUser!);
  }

  String _getMockFullName(String login, UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Администратор';
      case UserRole.expert:
        return 'Эксперт Иванов';
      case UserRole.team:
        return 'Команда ByteForce';
      case UserRole.public:
        return 'Гость';
    }
  }

  /// Выход из системы
  Future<void> logout() async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken != null && !_config.mockEnabled) {
        await _authApi.logout(refreshToken);
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      await _tokenStorage.clearTokens();
      _currentUser = null;
    }
  }

  /// Обновление токена (если нужно)
  Future<bool> refreshTokenIfNeeded() async {
    if (!_config.mockEnabled) {
      final shouldRefresh = await _tokenStorage.shouldRefreshToken(
        _config.refreshBeforeExpiryMinutes,
      );

      if (shouldRefresh) {
        try {
          final refreshToken = await _tokenStorage.getRefreshToken();
          if (refreshToken != null) {
            final result = await _authApi.refresh(refreshToken);
            await _tokenStorage.saveTokens(
              accessToken: result['access_token'],
              refreshToken: refreshToken,
            );
            return true;
          }
        } catch (e) {
          debugPrint('Token refresh error: $e');
          await logout();
        }
      }
    }
    return false;
  }

  /// Смена пароля
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      if (_config.mockEnabled) {
        await Future.delayed(const Duration(milliseconds: 300));
        return true;
      }
      await _authApi.changePassword(oldPassword, newPassword);
      return true;
    } catch (e) {
      return false;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is Map && error.containsKey('message')) {
      return error['message'];
    }
    if (error.toString().contains('401')) {
      return 'Неверный логин или пароль';
    }
    return 'Ошибка авторизации. Проверьте подключение к серверу.';
  }
}

/// Результат авторизации
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
