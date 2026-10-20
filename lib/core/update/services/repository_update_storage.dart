import 'update_storage.dart';

/// Adapter implementation of [UpdateStorageInterface] that delegates to any
/// key-value reader and writer (such as SettingsRepository or SharedPreferences).
class RepositoryUpdateStorage implements UpdateStorageInterface {
  final Future<String?> Function(String key) reader;
  final Future<void> Function(String key, String value) writer;

  static const String _keyLastChecked = 'app_update_last_checked_at';
  static const String _keyCachedVersion = 'app_update_cached_remote_version';

  const RepositoryUpdateStorage({
    required this.reader,
    required this.writer,
  });

  @override
  Future<DateTime?> getLastCheckTime() async {
    try {
      final value = await reader(_keyLastChecked);
      if (value != null && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> setLastCheckTime(DateTime time) async {
    try {
      await writer(_keyLastChecked, time.toIso8601String());
    } catch (_) {}
  }

  @override
  Future<String?> getCachedLatestVersion() async {
    try {
      return await reader(_keyCachedVersion);
    } catch (_) {}
    return null;
  }

  @override
  Future<void> setCachedLatestVersion(String version) async {
    try {
      await writer(_keyCachedVersion, version);
    } catch (_) {}
  }

  @override
  Future<void> clear() async {
    try {
      await writer(_keyLastChecked, '');
      await writer(_keyCachedVersion, '');
    } catch (_) {}
  }
}
