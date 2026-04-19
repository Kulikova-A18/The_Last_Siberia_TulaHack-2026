import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  static AppConfig? _instance;

  late final String baseUrl;
  late final String apiPrefix;
  late final int connectTimeout;
  late final int receiveTimeout;
  late final int sendTimeout;
  late final bool useProxy;

  late final String wsUrl;
  late final String wsPrefix;
  late final int wsPingInterval;

  late final int accessTokenLifetimeMinutes;
  late final int refreshBeforeExpiryMinutes;
  late final int maxRefreshAttempts;

  late final String defaultHackathonId;

  late final bool mockEnabled;
  late final bool websocketEnabled;
  late final bool auditEnabled;
  late final int draftAutosaveInterval;

  late final String logLevel;
  late final bool logRequests;
  late final bool logResponses;

  late final String environment;

  late final String version;
  late final String buildNumber;

  AppConfig._fromMap(Map<dynamic, dynamic> config) {
    final api = config['api'] as Map<dynamic, dynamic>? ?? {};
    baseUrl = api['base_url']?.toString() ?? 'http://localhost:8000';
    apiPrefix = api['prefix']?.toString() ?? '/api/v1';
    useProxy = api['use_proxy'] as bool? ?? false;

    final timeout = api['timeout'] as Map<dynamic, dynamic>? ?? {};
    connectTimeout = timeout['connect'] as int? ?? 10;
    receiveTimeout = timeout['receive'] as int? ?? 30;
    sendTimeout = timeout['send'] as int? ?? 30;

    final websocket = config['websocket'] as Map<dynamic, dynamic>? ?? {};
    wsUrl = websocket['url']?.toString() ?? 'ws://localhost:8000';
    wsPrefix = websocket['prefix']?.toString() ?? '/api/v1/ws';
    wsPingInterval = websocket['ping_interval'] as int? ?? 30;

    final auth = config['auth'] as Map<dynamic, dynamic>? ?? {};
    accessTokenLifetimeMinutes =
        auth['access_token_lifetime_minutes'] as int? ?? 15;
    refreshBeforeExpiryMinutes =
        auth['refresh_before_expiry_minutes'] as int? ?? 2;
    maxRefreshAttempts = auth['max_refresh_attempts'] as int? ?? 3;

    final hackathon = config['hackathon'] as Map<dynamic, dynamic>? ?? {};
    defaultHackathonId = hackathon['default_id']?.toString() ?? '';

    final features = config['features'] as Map<dynamic, dynamic>? ?? {};
    mockEnabled = features['mock_enabled'] as bool? ?? false;
    websocketEnabled = features['websocket_enabled'] as bool? ?? true;
    auditEnabled = features['audit_enabled'] as bool? ?? true;
    draftAutosaveInterval = features['draft_autosave_interval'] as int? ?? 30;

    final logging = config['logging'] as Map<dynamic, dynamic>? ?? {};
    logLevel = logging['level']?.toString() ?? 'info';
    logRequests = logging['log_requests'] as bool? ?? true;
    logResponses = logging['log_responses'] as bool? ?? false;

    environment = config['environment']?.toString() ?? 'development';

    final build = config['build'] as Map<dynamic, dynamic>? ?? {};
    version = build['version']?.toString() ?? '1.0.0';
    buildNumber = build['build_number']?.toString() ?? '1';

    debugPrint(
        'Config loaded: baseUrl=$baseUrl, mockEnabled=$mockEnabled, useProxy=$useProxy');
  }

  static Future<AppConfig> getInstance() async {
    if (_instance != null) return _instance!;

    try {
      String yamlString;
      try {
        yamlString = await rootBundle.loadString('assets/config.yaml');
        debugPrint('Loaded config.yaml from assets');
      } catch (e) {
        debugPrint('Config file not found, using defaults: $e');
        yamlString = _getDefaultConfig();
      }

      final yamlMap = loadYaml(yamlString);
      if (yamlMap is Map) {
        _instance = AppConfig._fromMap(yamlMap);
      } else {
        _instance = AppConfig._fromMap(loadYaml(_getDefaultConfig()) as Map);
      }
    } catch (e, stack) {
      debugPrint('Error loading config: $e');
      _instance = AppConfig._createDefault();
    }

    return _instance!;
  }

  static AppConfig _createDefault() {
    final defaultMap = <dynamic, dynamic>{
      'api': <dynamic, dynamic>{
        'base_url': 'http://localhost:8000',
        'prefix': '/api/v1',
        'use_proxy': false,
        'timeout': <dynamic, dynamic>{'connect': 10, 'receive': 30, 'send': 30},
      },
      'websocket': <dynamic, dynamic>{
        'url': 'ws://localhost:8000',
        'prefix': '/api/v1/ws',
        'ping_interval': 30,
      },
      'auth': <dynamic, dynamic>{
        'access_token_lifetime_minutes': 15,
        'refresh_before_expiry_minutes': 2,
        'max_refresh_attempts': 3,
      },
      'hackathon': <dynamic, dynamic>{'default_id': ''},
      'features': <dynamic, dynamic>{
        'mock_enabled': false,
        'websocket_enabled': true,
        'audit_enabled': true,
        'draft_autosave_interval': 30,
      },
      'logging': <dynamic, dynamic>{
        'level': 'debug',
        'log_requests': true,
        'log_responses': false,
      },
      'environment': 'development',
      'build': <dynamic, dynamic>{'version': '1.0.0', 'build_number': '1'},
    };
    return AppConfig._fromMap(defaultMap);
  }

  static String _getDefaultConfig() {
    return '''
api:
  base_url: "http://94.141.160.86:8000"
  prefix: "/api/v1"
  use_proxy: false
  timeout:
    connect: 10
    receive: 30
    send: 30
websocket:
  url: "ws://94.141.160.86:8000"
  prefix: "/api/v1/ws"
  ping_interval: 30
auth:
  access_token_lifetime_minutes: 15
  refresh_before_expiry_minutes: 2
  max_refresh_attempts: 3
hackathon:
  default_id: ""
features:
  mock_enabled: false
  websocket_enabled: true
  audit_enabled: true
  draft_autosave_interval: 30
logging:
  level: "debug"
  log_requests: true
  log_responses: false
environment: "development"
build:
  version: "1.0.0"
  build_number: "1"
''';
  }

  String get fullApiUrl => useProxy ? apiPrefix : '$baseUrl$apiPrefix';
  String get fullWsUrl => '$wsUrl$wsPrefix';
  bool get isDevelopment => environment == 'development';
  bool get isProduction => environment == 'production';

  Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static AppConfig get instance {
    if (_instance == null) {
      throw Exception('AppConfig not initialized. Call getInstance() first.');
    }
    return _instance!;
  }
}
