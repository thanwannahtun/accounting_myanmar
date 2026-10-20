import 'package:equatable/equatable.dart';

/// Status of the OTA update download and install pipeline.
enum OtaDownloadStatus {
  idle,
  downloading,
  installing,
  alreadyRunning,
  permissionNotGranted,
  internalError,
  downloadError,
  checksumError,
  completed,
}

/// Progress event emitted during APK download and installation.
class AppUpdateProgress extends Equatable {
  final OtaDownloadStatus status;
  final int percentage; // 0 to 100
  final String? message;

  const AppUpdateProgress({
    required this.status,
    this.percentage = 0,
    this.message,
  });

  /// Fraction between 0.0 and 1.0 for ProgressIndicators
  double get fraction => (percentage.clamp(0, 100)) / 100.0;

  bool get isDownloading => status == OtaDownloadStatus.downloading;
  bool get isInstalling => status == OtaDownloadStatus.installing;
  bool get isCompleted => status == OtaDownloadStatus.completed;
  bool get hasError =>
      status == OtaDownloadStatus.internalError ||
      status == OtaDownloadStatus.downloadError ||
      status == OtaDownloadStatus.checksumError ||
      status == OtaDownloadStatus.permissionNotGranted;

  @override
  List<Object?> get props => [status, percentage, message];
}
