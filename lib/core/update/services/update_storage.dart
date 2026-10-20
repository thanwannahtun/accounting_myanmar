/// Decoupled storage interface for tracking update check timestamps and cached release versions.
abstract class UpdateStorageInterface {
  Future<DateTime?> getLastCheckTime();
  Future<void> setLastCheckTime(DateTime time);
  Future<String?> getCachedLatestVersion();
  Future<void> setCachedLatestVersion(String version);
  Future<void> clear();
}

/// In-memory storage useful for testing or ephemeral caching.
class InMemoryUpdateStorage implements UpdateStorageInterface {
  DateTime? _lastCheck;
  String? _cachedVersion;

  InMemoryUpdateStorage({DateTime? initialLastCheck, String? initialCachedVersion})
      : _lastCheck = initialLastCheck,
        _cachedVersion = initialCachedVersion;

  @override
  Future<DateTime?> getLastCheckTime() async => _lastCheck;

  @override
  Future<void> setLastCheckTime(DateTime time) async {
    _lastCheck = time;
  }

  @override
  Future<String?> getCachedLatestVersion() async => _cachedVersion;

  @override
  Future<void> setCachedLatestVersion(String version) async {
    _cachedVersion = version;
  }

  @override
  Future<void> clear() async {
    _lastCheck = null;
    _cachedVersion = null;
  }
}
