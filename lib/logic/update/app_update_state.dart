import 'package:equatable/equatable.dart';

import '../../core/update/models/app_version_info.dart';
import '../../core/update/models/update_info.dart';

enum AppUpdateStatus {
  initial,
  checking,
  upToDate,
  updateAvailable,
  downloading,
  installing,
  installationDone,
  error,
}

class AppUpdateState extends Equatable {
  final AppUpdateStatus status;
  final AppVersionInfo currentVersion;
  final String? latestVersion;
  final UpdateInfo? updateInfo;
  final int downloadPercentage;
  final String? downloadMessage;
  final String? errorMessage;
  final bool isManualCheck;
  final DateTime? lastCheckedAt;

  const AppUpdateState({
    this.status = AppUpdateStatus.initial,
    this.currentVersion = AppVersionInfo.empty,
    this.latestVersion,
    this.updateInfo,
    this.downloadPercentage = 0,
    this.downloadMessage,
    this.errorMessage,
    this.isManualCheck = false,
    this.lastCheckedAt,
  });

  bool get hasUpdateAvailable =>
      status == AppUpdateStatus.updateAvailable ||
      (status == AppUpdateStatus.downloading && updateInfo != null) ||
      (status == AppUpdateStatus.installing && updateInfo != null);

  bool get isChecking => status == AppUpdateStatus.checking;
  bool get isDownloading => status == AppUpdateStatus.downloading;
  bool get isInstalling => status == AppUpdateStatus.installing;

  AppUpdateState copyWith({
    AppUpdateStatus? status,
    AppVersionInfo? currentVersion,
    String? latestVersion,
    UpdateInfo? updateInfo,
    int? downloadPercentage,
    String? downloadMessage,
    String? errorMessage,
    bool? isManualCheck,
    DateTime? lastCheckedAt,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      updateInfo: updateInfo ?? this.updateInfo,
      downloadPercentage: downloadPercentage ?? this.downloadPercentage,
      downloadMessage: downloadMessage ?? this.downloadMessage,
      errorMessage: errorMessage,
      isManualCheck: isManualCheck ?? this.isManualCheck,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentVersion,
        latestVersion,
        updateInfo,
        downloadPercentage,
        downloadMessage,
        errorMessage,
        isManualCheck,
        lastCheckedAt,
      ];
}
