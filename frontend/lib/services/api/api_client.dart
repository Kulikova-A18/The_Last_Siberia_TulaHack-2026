import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';
import '../token_storage.dart';
import '../auth_service.dart';

// Глобальный коллбэк для логирования в UI
typedef ApiLogCallback = void Function(String message);

class ApiClient {
  static ApiClient? _instance;
  static ApiLogCallback? _logCallback;

  late final Dio _dio;
  late final TokenStorage _tokenStorage;
  late final AppConfig _config;

  AuthService? _authService;
  bool _isRefreshing = false;
  final List<Completer<void>> _refreshCompleters = [];

  ApiClient._({
    required AppConfig config,
    required TokenStorage tokenStorage,
  })  : _config = config,
        _tokenStorage = tokenStorage {
    _dio = Dio(BaseOptions(
      baseUrl: config.fullApiUrl,
      connectTimeout: Duration(seconds: config.connectTimeout),
      receiveTimeout: Duration(seconds: config.receiveTimeout),
      sendTimeout: Duration(seconds: config.sendTimeout),
      headers: config.defaultHeaders,
      validateStatus: (status) => status != null && status < 500,
    ));
    _setupInterceptors();
  }

  static ApiClient getInstance({
    required AppConfig config,
    required TokenStorage tokenStorage,
  }) {
    _instance ??= ApiClient._(config: config, tokenStorage: tokenStorage);
    return _instance!;
  }

  static void setLogCallback(ApiLogCallback callback) {
    _logCallback = callback;
  }

  void _log(String message) {
    debugPrint(message);
    _logCallback?.call(message);
  }

  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // Логируем запрос
        final method = options.method;
        final path = options.path;
        final hasToken = token != null ? '🔐' : '🌐';
        _log('📤 $hasToken $method $path');
        if (options.data != null) {
          _log('   Body: ${_truncate(options.data.toString())}');
        }
        if (options.queryParameters.isNotEmpty) {
          _log('   Query: ${options.queryParameters}');
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Логируем ответ
        final statusCode = response.statusCode;
        final emoji = statusCode != null && statusCode < 300 ? '✅' : '⚠️';
        _log('📥 $emoji HTTP $statusCode ${response.requestOptions.path}');

        return handler.next(response);
      },
      onError: (DioException error, handler) async {
        // Логируем ошибку
        _log('❌ ERROR: ${error.message}');
        if (error.response != null) {
          _log('   Status: ${error.response?.statusCode}');
          _log('   Body: ${_truncate(error.response?.data.toString() ?? '')}');
        }

        if (error.response?.statusCode == 401) {
          _log('🔄 Attempting token refresh...');
          final shouldRetry = await _handleUnauthorized(error);
          if (shouldRetry) {
            _log('✅ Token refreshed, retrying request');
            final retryOptions = error.requestOptions;
            final newToken = await _tokenStorage.getAccessToken();
            if (newToken != null) {
              retryOptions.headers['Authorization'] = 'Bearer $newToken';
              try {
                final response = await _dio.fetch(retryOptions);
                return handler.resolve(response);
              } catch (e) {
                _log('❌ Retry failed: $e');
                return handler.reject(e as DioException);
              }
            }
          } else {
            _log('❌ Token refresh failed');
          }

          if (_authService != null &&
              error.requestOptions.path != '/auth/login' &&
              error.requestOptions.path != '/auth/refresh') {
            await _authService!.logout();
            _log('👋 Logged out due to auth failure');
          }
        }

        return handler.next(error);
      },
    ));
  }

  String _truncate(String text, {int maxLength = 200}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Future<bool> _handleUnauthorized(DioException error) async {
    if (_isRefreshing) {
      final completer = Completer<void>();
      _refreshCompleters.add(completer);
      await completer.future;
      return true;
    }
    _isRefreshing = true;
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) return false;
      final response = await _dio
          .post('/auth/refresh', data: {'refresh_token': refreshToken});
      if (response.statusCode == 200) {
        final newAccessToken = response.data['access_token'];
        final newRefreshToken = response.data['refresh_token'];
        await _tokenStorage.saveTokens(
            accessToken: newAccessToken, refreshToken: newRefreshToken);
        for (final completer in _refreshCompleters) {
          completer.complete();
        }
        return true;
      }
      return false;
    } catch (e) {
      for (final completer in _refreshCompleters) {
        completer.completeError(e);
      }
      return false;
    } finally {
      _isRefreshing = false;
      _refreshCompleters.clear();
    }
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters, Options? options}) async {
    return await _dio.get(path,
        queryParameters: queryParameters, options: options);
  }

  Future<Response> post(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    return await _dio.post(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> put(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    return await _dio.put(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> patch(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    return await _dio.patch(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> delete(String path,
      {dynamic data,
      Map<String, dynamic>? queryParameters,
      Options? options}) async {
    return await _dio.delete(path,
        data: data, queryParameters: queryParameters, options: options);
  }
}
