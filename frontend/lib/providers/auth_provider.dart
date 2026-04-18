import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';
import '../services/api/api_service.dart';
import '../services/api/api_client.dart';
import '../config/app_config.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.instance);

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient.getInstance(config: config, tokenStorage: tokenStorage);
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiService(client);
});

final authServiceProvider = Provider<AuthService>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final apiService = ref.watch(apiServiceProvider);
  final config = ref.watch(appConfigProvider);
  final authService = AuthService(
    tokenStorage: tokenStorage,
    apiService: apiService,
    config: config,
  );
  ref.watch(apiClientProvider).setAuthService(authService);
  return authService;
});

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
      debugPrint('🔄 AuthNotifier: Initializing...');
      final success = await _authService.initialize();
      if (success) {
        debugPrint('✅ AuthNotifier: User restored from storage');
        state = AsyncValue.data(_authService.currentUser);
      } else {
        debugPrint('ℹ️ AuthNotifier: No valid session found');
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      debugPrint('❌ AuthNotifier: Init error: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<AuthResult> login(String login, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await _authService.login(login, password);
      if (result.success) {
        debugPrint('✅ AuthNotifier: Login successful, updating state');
        state = AsyncValue.data(_authService.currentUser);
      } else {
        debugPrint('❌ AuthNotifier: Login failed');
        state = const AsyncValue.data(null);
      }
      return result;
    } catch (e, st) {
      debugPrint('❌ AuthNotifier: Login exception: $e');
      state = AsyncValue.error(e, st);
      return AuthResult.failure(e.toString());
    }
  }

  Future<void> logout() async {
    try {
      debugPrint('🔄 AuthNotifier: Logging out...');
      await _authService.logout();
      state = const AsyncValue.data(null);
      debugPrint('✅ AuthNotifier: Logged out');
    } catch (e, st) {
      debugPrint('❌ AuthNotifier: Logout error: $e');
      state = AsyncValue.error(e, st);
    }
  }
}

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull;
});

final hackathonIdProvider = FutureProvider<String>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  try {
    final hackathon = await apiService.getActiveHackathon();
    return hackathon?.id ?? '';
  } catch (e) {
    debugPrint('❌ Failed to get active hackathon: $e');
    return '';
  }
});
