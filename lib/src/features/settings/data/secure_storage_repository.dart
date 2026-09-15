import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageRepository {
  final FlutterSecureStorage? _storage;
  final Map<String, String>? _inMemoryStorage;

  static const String _keyApiKey = 'gemini_api_key';

  SecureStorageRepository([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage(),
        _inMemoryStorage = null;

  SecureStorageRepository.inMemory([Map<String, String>? storage])
      : _storage = null,
        _inMemoryStorage = storage ?? {};

  Future<String?> getApiKey() async {
    if (_inMemoryStorage != null) {
      return _inMemoryStorage[_keyApiKey];
    }
    return await _storage?.read(key: _keyApiKey);
  }

  Future<void> setApiKey(String apiKey) async {
    if (_inMemoryStorage != null) {
      if (apiKey.trim().isEmpty) {
        _inMemoryStorage.remove(_keyApiKey);
      } else {
        _inMemoryStorage[_keyApiKey] = apiKey.trim();
      }
      return;
    }
    if (apiKey.trim().isEmpty) {
      await _storage?.delete(key: _keyApiKey);
    } else {
      await _storage?.write(key: _keyApiKey, value: apiKey.trim());
    }
  }

  Future<void> deleteApiKey() async {
    if (_inMemoryStorage != null) {
      _inMemoryStorage.remove(_keyApiKey);
      return;
    }
    await _storage?.delete(key: _keyApiKey);
  }
}
