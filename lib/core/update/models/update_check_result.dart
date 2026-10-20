import 'package:equatable/equatable.dart';

import 'app_version_info.dart';
import 'update_info.dart';

/// The result returned by checking for application updates.
class UpdateCheckResult extends Equatable {
  /// Whether a newer version is available compared to the currently running version.
  final bool hasUpdate;

  /// The currently installed application version.
  final AppVersionInfo currentVersion;

  /// The remote release tag / version string (e.g. "v1.0.1" or "1.0.1").
  final String latestVersion;

  /// Detailed release info and APK download attributes, if available.
  final UpdateInfo? releaseInfo;

  /// Timestamp when the check was performed.
  final DateTime checkedAt;

  /// Whether this check was triggered manually by the user (vs periodic background).
  final bool isManual;

  /// Error message if the update check failed.
  final String? error;

  const UpdateCheckResult({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    this.releaseInfo,
    required this.checkedAt,
    this.isManual = false,
    this.error,
  });

  /// Factory for a failed update check
  factory UpdateCheckResult.failure({
    required AppVersionInfo currentVersion,
    required String error,
    bool isManual = false,
  }) {
    return UpdateCheckResult(
      hasUpdate: false,
      currentVersion: currentVersion,
      latestVersion: currentVersion.versionWithBuild,
      checkedAt: DateTime.now(),
      isManual: isManual,
      error: error,
    );
  }

  /// Whether the check completed successfully without errors
  bool get isSuccess => error == null;

  @override
  List<Object?> get props => [
        hasUpdate,
        currentVersion,
        latestVersion,
        releaseInfo,
        checkedAt,
        isManual,
        error,
      ];
}
