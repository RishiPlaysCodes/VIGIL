import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provides encrypted storage for sensitive data like tokens and PINs.
/// Uses platform keychain (iOS) and EncryptedSharedPreferences (Android).
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Keys
  static const _keyApiToken = 'api_token';
  static const _keyUserId = 'user_id';
  static const _keyUsername = 'username';
  static const _keySecurityPin = 'security_pin';

  // Token management
  Future<void> saveAuthSession({
    required int userId,
    required String username,
    required String token,
  }) async {
    await _storage.write(key: _keyApiToken, value: token);
    await _storage.write(key: _keyUserId, value: userId.toString());
    await _storage.write(key: _keyUsername, value: username);
  }

  Future<({int? userId, String? username, String? token})> getAuthSession() async {
    final token = await _storage.read(key: _keyApiToken);
    final userIdStr = await _storage.read(key: _keyUserId);
    final username = await _storage.read(key: _keyUsername);
    return (
      userId: userIdStr != null ? int.tryParse(userIdStr) : null,
      username: username,
      token: token,
    );
  }

  Future<void> clearAuthSession() async {
    await _storage.delete(key: _keyApiToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUsername);
  }

  // PIN management
  Future<void> saveSecurityPin(String pin) async {
    await _storage.write(key: _keySecurityPin, value: pin);
  }

  Future<String?> getSecurityPin() async {
    return _storage.read(key: _keySecurityPin);
  }

  Future<bool> hasSecurityPin() async {
    final pin = await _storage.read(key: _keySecurityPin);
    return pin != null && pin.isNotEmpty;
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
