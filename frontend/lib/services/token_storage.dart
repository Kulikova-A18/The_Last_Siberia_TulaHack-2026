import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

/// Безопасное хранилище токенов с использованием flutter_secure_storage
class TokenStorage {
  static const String _accessTokenKey = 'hackrank_access_token';
  static const String _refreshTokenKey = 'hackrank_refresh_token';
  static const String _tokenExpiryKey = 'hackrank_token_expiry';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);

    // Сохраняем время истечения токена
    final expiry = _getTokenExpiry(accessToken);
    if (expiry != null) {
      await _storage.write(
          key: _tokenExpiryKey, value: expiry.toIso8601String());
    }
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<DateTime?> getTokenExpiry() async {
    final expiryStr = await _storage.read(key: _tokenExpiryKey);
    if (expiryStr == null) return null;
    return DateTime.parse(expiryStr);
  }

  Future<bool> isTokenExpired({Duration? threshold}) async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;

    final now = DateTime.now();
    final checkTime = threshold != null ? expiry.subtract(threshold) : expiry;

    return now.isAfter(checkTime);
  }

  Future<bool> shouldRefreshToken(int refreshBeforeMinutes) async {
    return await isTokenExpired(
      threshold: Duration(minutes: refreshBeforeMinutes),
    );
  }

  DateTime? _getTokenExpiry(String token) {
    try {
      final payload = Jwt.parseJwt(token);
      final exp = payload['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
    } catch (e) {
      // Игнорируем ошибки декодирования
    }
    return null;
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tokenExpiryKey);
  }

  Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();

    if (accessToken == null || refreshToken == null) return false;

    return !(await isTokenExpired());
  }
}
