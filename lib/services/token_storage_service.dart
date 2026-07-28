import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorageService {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
  Future<bool> hasToken();
}

class SecureTokenStorageService implements TokenStorageService {
  static const _tokenKey = 'discogs_token';

  final FlutterSecureStorage _storage;

  SecureTokenStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              webOptions: WebOptions(
                dbName: 'vinyl_collection_secure_storage',
                publicKey: 'vinyl_collection_public_key',
              ),
            );

  @override
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token.trim());
  }

  @override
  Future<String?> getToken() async {
    final value = await _storage.read(key: _tokenKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  @override
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  @override
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}