import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/update/models/update_progress.dart';
import '../../core/update/services/app_update_service_interface.dart';
import 'app_update_state.dart';

class AppUpdateCubit extends Cubit<AppUpdateState> {
  final AppUpdateServiceInterface updateService;
  StreamSubscription<AppUpdateProgress>? _downloadSub;

  AppUpdateCubit({required this.updateService})
      : super(const AppUpdateState());

  /// Initializes the cubit by dynamically retrieving the installed app version
  /// and running a non-intrusive periodic background check if 7 days have passed.
  Future<void> init() async {
    try {
      final currentVersion = await updateService.checkCurrentApkVersion();
      emit(state.copyWith(currentVersion: currentVersion));

      // Trigger automatic weekly check quietly in the background
      final isDue = await updateService.shouldPerformPeriodicCheck();
      if (isDue) {
        await checkForUpdates(force: false);
      }
    } catch (_) {
      // Ignored during startup to never interrupt core app flows
    }
  }

  /// Checks remote repository for new updates.
  /// Set [force] to true when triggered manually by user tap.
  Future<void> checkForUpdates({bool force = false}) async {
    emit(
      state.copyWith(
        status: AppUpdateStatus.checking,
        isManualCheck: force,
        errorMessage: null,
      ),
    );

    try {
      final result = await updateService.checkForVersionUpdate(force: force);

      if (result.hasUpdate && result.releaseInfo != null) {
        emit(
          state.copyWith(
            status: AppUpdateStatus.updateAvailable,
            currentVersion: result.currentVersion,
            latestVersion: result.latestVersion,
            updateInfo: result.releaseInfo,
            lastCheckedAt: result.checkedAt,
            isManualCheck: force,
          ),
        );
      } else if (result.error != null) {
        emit(
          state.copyWith(
            status: force ? AppUpdateStatus.error : state.status,
            currentVersion: result.currentVersion,
            errorMessage: result.error,
            isManualCheck: force,
            lastCheckedAt: result.checkedAt,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: AppUpdateStatus.upToDate,
            currentVersion: result.currentVersion,
            latestVersion: result.latestVersion,
            lastCheckedAt: result.checkedAt,
            isManualCheck: force,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: force ? AppUpdateStatus.error : state.status,
          errorMessage: 'Check update failed: $e',
          isManualCheck: force,
        ),
      );
    }
  }

  /// Downloads the latest APK with progress reporting and initiates the OS installer.
  Future<void> startDownloadAndInstall({String? customApkUrl}) async {
    final apkUrl = customApkUrl ?? state.updateInfo?.apkDownloadUrl;
    if (apkUrl == null || apkUrl.isEmpty) {
      emit(
        state.copyWith(
          status: AppUpdateStatus.error,
          errorMessage: 'No APK download link found for this release.',
        ),
      );
      return;
    }

    await _downloadSub?.cancel();

    emit(
      state.copyWith(
        status: AppUpdateStatus.downloading,
        downloadPercentage: 0,
        downloadMessage: 'Connecting to download server...',
        errorMessage: null,
      ),
    );

    _downloadSub = updateService
        .downloadLatestAPK(
      apkUrl,
      destinationFilename: state.updateInfo?.apkFileName,
    )
        .listen(
      (progress) {
        if (progress.isDownloading) {
          emit(
            state.copyWith(
              status: AppUpdateStatus.downloading,
              downloadPercentage: progress.percentage,
              downloadMessage: progress.message,
            ),
          );
        } else if (progress.isInstalling) {
          emit(
            state.copyWith(
              status: AppUpdateStatus.installing,
              downloadPercentage: 100,
              downloadMessage: progress.message ?? 'Launching installer...',
            ),
          );
        } else if (progress.isCompleted) {
          emit(
            state.copyWith(
              status: AppUpdateStatus.installationDone,
              downloadPercentage: 100,
              downloadMessage: 'Installation package launched.',
            ),
          );
        } else if (progress.hasError) {
          emit(
            state.copyWith(
              status: AppUpdateStatus.error,
              errorMessage: progress.message ?? 'Failed to download or install update.',
            ),
          );
        }
      },
      onError: (err) {
        emit(
          state.copyWith(
            status: AppUpdateStatus.error,
            errorMessage: 'Download error: $err',
          ),
        );
      },
    );
  }

  /// Opens the release or web page in external browser.
  Future<void> openInBrowser() async {
    final url = state.updateInfo?.htmlUrl ?? '';
    await updateService.openReleaseInBrowser(url);
  }

  @override
  Future<void> close() async {
    await _downloadSub?.cancel();
    return super.close();
  }
}
