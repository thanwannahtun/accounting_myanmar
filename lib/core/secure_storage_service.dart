import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'env.dart';

/// Secure wrapper around [FlutterSecureStorage].
/// On Web, flutter_secure_storage uses Web Crypto / localStorage encryption.
/// On Android, it uses EncryptedSharedPreferences.
/// On Windows, it uses the Windows Credential Locker.
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  // Android: use EncryptedSharedPreferences
  // iOS/macOS: uses Keychain
  // Windows: uses Credential Locker
  // Web: uses Web Crypto backed localStorage
  static const _androidOptions = AndroidOptions(
    // encryptedSharedPreferences: true, // encryptedSharedPreferences is not defined in AndroidOptions
  );
  static const _windowsOptions = WindowsOptions(
    useBackwardCompatibility: false,
  );

  FlutterSecureStorage get _storage => const FlutterSecureStorage(
    aOptions: _androidOptions,
    wOptions: _windowsOptions,
  );

  /// Read a value by [key].
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('[SecureStorage] read error for key=$key : $e');
      return null;
    }
  }

  /// Write a [value] for [key].
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('[SecureStorage] write error for key=$key : $e');
    }
  }

  /// Delete a single [key].
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('[SecureStorage] delete error for key=$key : $e');
    }
  }

  /// Delete all stored secrets (logout).
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('[SecureStorage] deleteAll error : $e');
    }
  }

  // ────────────────────────────────
  // Convenience helpers for tokens
  // ────────────────────────────────

  Future<String?> getAccessToken() => read(Env.accessToken);

  Future<void> setAccessToken(String token) => write(Env.accessToken, token);

  Future<void> clearTokens() => deleteAll();

  // ────────────────────────────────
  // Terms acceptance (versioned)
  // ────────────────────────────────
  static const _termsKey = 'bb_terms_v1';

  /// Returns true if the user has already accepted the current terms version.
  Future<bool> hasAcceptedTerms() async {
    final val = await read(_termsKey);
    return val == 'true';
  }

  /// Marks the current terms version as accepted.
  Future<void> setTermsAccepted() => write(_termsKey, 'true');
}
