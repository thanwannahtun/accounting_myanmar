import '../models/app_version_info.dart';
import '../models/update_check_result.dart';
import '../models/update_config.dart';
import '../models/update_progress.dart';

/// Clean, decoupled interface defining the version update lifecycle.
///
/// Implements single-responsibility principles so it can be easily tested,
/// mocked, or transferred to other Flutter applications without coupling.
abstract class AppUpdateServiceInterface {
  /// The configuration used by this update service.
  UpdateConfig get config;

  /// Inspects and returns the currently installed app version metadata dynamically
  /// using [package_info_plus].
  Future<AppVersionInfo> checkCurrentApkVersion();

  /// Checks remote release repository (e.g. GitHub Releases) for newer versions.
  ///
  /// If [force] is false and a periodic check is not yet due according to
  /// [config.checkInterval], it can return cached result or perform the check.
  Future<UpdateCheckResult> checkForVersionUpdate({bool force = false});

  /// Checks if the periodic interval (e.g., 7 days) has elapsed since the last check.
  Future<bool> shouldPerformPeriodicCheck();

  /// Records the current timestamp as the last update check time.
  Future<void> recordUpdateCheckTimestamp();

  /// Downloads the latest APK file and triggers the native OS installation via [ota_update].
  ///
  /// Returns a [Stream] of [AppUpdateProgress] emitting real-time percentage and status.
  Stream<AppUpdateProgress> downloadLatestAPK(
    String apkUrl, {
    String? destinationFilename,
    String? sha256Checksum,
  });

  /// Opens the release or download URL in the device's external browser.
  ///
  /// Used on non-Android platforms (Windows, Linux, macOS, Web, iOS) or as an
  /// error fallback when direct APK installation cannot be performed.
  Future<bool> openReleaseInBrowser(String url);
}
