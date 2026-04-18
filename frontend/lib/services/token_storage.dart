import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:flutter/foundation.dart';

class TokenStorage {
  static const String _accessTokenKey = 'hackrank_access_token';
  static const String _refreshTokenKey = 'hackrank_refresh_token';
  static const String _tokenExpiryKey = 'hackrank_token_expiry';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);

      final expiry = _getTokenExpiry(accessToken);
      if (expiry != null) {
        await _storage.write(
            key: _tokenExpiryKey, value: expiry.toIso8601String());
        debugPrint('💾 Token expiry: $expiry');
      }

      debugPrint('✅ Tokens saved successfully');
    } catch (e) {
      debugPrint('❌ Failed to save tokens: $e');
      rethrow;
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _accessTokenKey);
    } catch (e) {
      debugPrint('❌ Failed to read access token: $e');
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('❌ Failed to read refresh token: $e');
      return null;
    }
  }

  Future<DateTime?> getTokenExpiry() async {
    try {
      final expiryStr = await _storage.read(key: _tokenExpiryKey);
      if (expiryStr == null) return null;
      return DateTime.parse(expiryStr);
    } catch (e) {
      debugPrint('❌ Failed to read token expiry: $e');
      return null;
    }
  }

  Future<bool> isTokenExpired({Duration? threshold}) async {
    final expiry = await getTokenExpiry();
    if (expiry == null) {
      debugPrint('⚠️ No token expiry found, assuming expired');
      return true;
    }

    final now = DateTime.now();
    final checkTime = threshold != null ? expiry.subtract(threshold) : expiry;
    final isExpired = now.isAfter(checkTime);

    debugPrint(
        '🔐 Token check: now=$now, expiry=$expiry, isExpired=$isExpired');
    return isExpired;
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
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to decode JWT: $e');
    }
    return null;
  }

  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _tokenExpiryKey);
      debugPrint('🧹 Tokens cleared from storage');
    } catch (e) {
      debugPrint('❌ Failed to clear tokens: $e');
    }
  }

  Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();

    if (accessToken == null || refreshToken == null) {
      debugPrint(
          '⚠️ Missing tokens: access=${accessToken != null}, refresh=${refreshToken != null}');
      return false;
    }

    final isExpired = await isTokenExpired();
    debugPrint(
        '🔐 Token validation: access token exists, isExpired=$isExpired');
    return !isExpired;
  }
}
