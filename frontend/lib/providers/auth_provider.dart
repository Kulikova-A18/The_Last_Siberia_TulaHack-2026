import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';
import '../services/api/auth_api.dart';
import '../services/api/api_client.dart';
import '../config/app_config.dart';

// Базовые провайдеры
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

// Конфиг загружается синхронно после инициализации
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.instance;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);

  return ApiClient.getInstance(
    config: config,
    tokenStorage: tokenStorage,
  );
});

final authApiProvider = Provider<AuthApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthApi(client);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final authApi = ref.watch(authApiProvider);
  final config = ref.watch(appConfigProvider);

  final authService = AuthService(
    tokenStorage: tokenStorage,
    authApi: authApi,
    config: config,
  );

  // Связываем ApiClient с AuthService для обработки 401
  ref.watch(apiClientProvider).setAuthService(authService);

  return authService;
});

// Состояние авторизации
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final success = await _authService.initialize();
      if (success) {
        state = AsyncValue.data(_authService.currentUser);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<AuthResult> login(String login, String password) async {
    state = const AsyncValue.loading();
    final result = await _authService.login(login, password);

    if (result.success) {
      state = AsyncValue.data(_authService.currentUser);
    } else {
      state = const AsyncValue.data(null);
    }

    return result;
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AsyncValue.data(null);
  }

  Future<bool> refreshTokenIfNeeded() async {
    return await _authService.refreshTokenIfNeeded();
  }
}

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull;
});

// Hackathon ID провайдер
final hackathonIdProvider = Provider<String>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.defaultHackathonId;
});
