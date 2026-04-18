import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';
import '../token_storage.dart';
import '../auth_service.dart';

/// HTTP клиент с поддержкой JWT авторизации и автоматическим обновлением токенов
class ApiClient {
  static ApiClient? _instance;

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

  void setAuthService(AuthService authService) {
    _authService = authService;
  }

  void _setupInterceptors() {
    // Request interceptor - добавляет токен
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        if (_config.logRequests) {
          _logRequest(options);
        }

        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (_config.logResponses) {
          _logResponse(response);
        }
        return handler.next(response);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401) {
          // Токен истек или невалиден - пробуем обновить
          final shouldRetry = await _handleUnauthorized(error);
          if (shouldRetry) {
            // Повторяем запрос с новым токеном
            final retryOptions = error.requestOptions;
            final newToken = await _tokenStorage.getAccessToken();

            if (newToken != null) {
              retryOptions.headers['Authorization'] = 'Bearer $newToken';
              try {
                final response = await _dio.fetch(retryOptions);
                return handler.resolve(response);
              } catch (e) {
                return handler.reject(e as DioException);
              }
            }
          }

          // Если не удалось обновить - разлогиниваем
          if (_authService != null &&
              error.requestOptions.path != '/auth/login' &&
              error.requestOptions.path != '/auth/refresh') {
            await _authService!.logout();
          }
        }

        return handler.next(error);
      },
    ));

    // Logging interceptor
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: _config.logRequests,
        responseBody: _config.logResponses,
      ));
    }
  }

  Future<bool> _handleUnauthorized(DioException error) async {
    if (_isRefreshing) {
      // Ждем завершения текущего обновления
      final completer = Completer<void>();
      _refreshCompleters.add(completer);
      await completer.future;
      return true;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access_token'];
        await _tokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: refreshToken,
        );

        // Уведомляем всех ожидающих
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

  void _logRequest(RequestOptions options) {
    debugPrint('🌐 REQUEST: ${options.method} ${options.uri}');
    if (options.data != null) {
      debugPrint('📤 Body: ${options.data}');
    }
  }

  void _logResponse(Response response) {
    debugPrint(
        '✅ RESPONSE: ${response.statusCode} ${response.requestOptions.uri}');
  }

  // Публичные методы API

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (_config.mockEnabled && _shouldMock(path)) {
      return _getMockResponse(path, queryParameters);
    }
    return await _dio.get(path,
        queryParameters: queryParameters, options: options);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (_config.mockEnabled && _shouldMock(path)) {
      return _getMockResponse(path, queryParameters,
          method: 'POST', data: data);
    }
    return await _dio.post(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.patch(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete(path,
        data: data, queryParameters: queryParameters, options: options);
  }

  bool _shouldMock(String path) {
    // В мок-режиме обрабатываем только определенные эндпоинты
    return true;
  }

  Response _getMockResponse(String path, Map<String, dynamic>? params,
      {String method = 'GET', dynamic data}) {
    // Здесь будет логика мок-ответов для демо-режима
    // Пока возвращаем заглушку
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: {'mock': true, 'path': path},
    );
  }
}
