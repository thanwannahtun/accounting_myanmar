import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_version_info.dart';
import '../models/update_check_result.dart';
import '../models/update_config.dart';
import '../models/update_info.dart';
import '../models/update_progress.dart';
import 'app_update_service_interface.dart';
import 'update_storage.dart';
import 'version_comparator.dart';

/// Production-ready GitHub Releases update lifecycle service.
///
/// Follows Single Responsibility and Dependency Inversion principles.
/// All GitHub credentials, repos, and file matching rules are decoupled via [UpdateConfig].
class GithubAppUpdateService implements AppUpdateServiceInterface {
  @override
  final UpdateConfig config;
  final http.Client _httpClient;
  final UpdateStorageInterface _storage;
  final Future<AppVersionInfo> Function()? customVersionProvider;

  GithubAppUpdateService({
    required this.config,
    http.Client? httpClient,
    UpdateStorageInterface? storage,
    this.customVersionProvider,
  })  : _httpClient = httpClient ?? http.Client(),
        _storage = storage ?? InMemoryUpdateStorage();

  /// Inspects and returns the currently installed app version metadata dynamically
  /// using [package_info_plus].
  @override
  Future<AppVersionInfo> checkCurrentApkVersion() async {
    final customProvider = customVersionProvider;
    if (customProvider != null) {
      return await customProvider();
    }
    try {
      final info = await PackageInfo.fromPlatform();
      return AppVersionInfo(
        appName: info.appName,
        packageName: info.packageName,
        version: info.version,
        buildNumber: info.buildNumber,
      );
    } catch (_) {
      // Graceful fallback for tests or headless environments
      return AppVersionInfo.empty;
    }
  }

  /// Checks if the periodic interval (e.g., 7 days) has elapsed since the last check.
  @override
  Future<bool> shouldPerformPeriodicCheck() async {
    final lastCheck = await _storage.getLastCheckTime();
    if (lastCheck == null) return true;
    final difference = DateTime.now().difference(lastCheck);
    return difference >= config.checkInterval;
  }

  /// Records the current timestamp as the last update check time.
  @override
  Future<void> recordUpdateCheckTimestamp() async {
    await _storage.setLastCheckTime(DateTime.now());
  }

  /// Checks GitHub latest release for newer APK version.
  ///
  /// If [force] is false and periodic interval has not elapsed, this check may return
  /// the cached status without hitting the remote network.
  @override
  Future<UpdateCheckResult> checkForVersionUpdate({bool force = false}) async {
    final current = await checkCurrentApkVersion();

    if (!force) {
      final isDue = await shouldPerformPeriodicCheck();
      if (!isDue) {
        final cached = await _storage.getCachedLatestVersion();
        if (cached != null && cached.isNotEmpty) {
          final hasUpdate = VersionComparator.isNewer(
            current.versionWithBuild,
            cached,
          );
          return UpdateCheckResult(
            hasUpdate: hasUpdate,
            currentVersion: current,
            latestVersion: cached,
            checkedAt: (await _storage.getLastCheckTime()) ?? DateTime.now(),
            isManual: false,
          );
        }
      }
    }

    try {
      final response = await _httpClient.get(
        config.latestReleaseUri,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'FlutterAppUpdateService-${current.appName}',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
        final releaseInfo = UpdateInfo.fromGitHubJson(
          data,
          apkAssetRegex: config.apkAssetRegex,
        );

        final remoteVersionTag = releaseInfo.tagName.isNotEmpty
            ? releaseInfo.tagName
            : releaseInfo.releaseName;

        final hasUpdate = VersionComparator.isNewer(
          current.versionWithBuild,
          remoteVersionTag,
        );

        await recordUpdateCheckTimestamp();
        await _storage.setCachedLatestVersion(remoteVersionTag);

        return UpdateCheckResult(
          hasUpdate: hasUpdate,
          currentVersion: current,
          latestVersion: remoteVersionTag,
          releaseInfo: releaseInfo,
          checkedAt: DateTime.now(),
          isManual: force,
        );
      } else if (response.statusCode == 404) {
        return UpdateCheckResult.failure(
          currentVersion: current,
          error: 'No releases found for ${config.githubOwner}/${config.githubRepo}.',
          isManual: force,
        );
      } else if (response.statusCode == 403) {
        return UpdateCheckResult.failure(
          currentVersion: current,
          error: 'GitHub API rate limit exceeded. Please try again later.',
          isManual: force,
        );
      } else {
        return UpdateCheckResult.failure(
          currentVersion: current,
          error: 'Failed to fetch release info (HTTP ${response.statusCode}).',
          isManual: force,
        );
      }
    } catch (e) {
      return UpdateCheckResult.failure(
        currentVersion: current,
        error: 'Network error checking for updates: $e',
        isManual: force,
      );
    }
  }

  /// Downloads the latest APK file and triggers the native OS installation via [ota_update].
  @override
  Stream<AppUpdateProgress> downloadLatestAPK(
    String apkUrl, {
    String? destinationFilename,
    String? sha256Checksum,
  }) async* {
    if (apkUrl.isEmpty) {
      yield const AppUpdateProgress(
        status: OtaDownloadStatus.downloadError,
        message: 'Download URL is empty or invalid.',
      );
      return;
    }

    // OTA installation is Android-only
    if (!Platform.isAndroid) {
      yield AppUpdateProgress(
        status: OtaDownloadStatus.internalError,
        message:
            'Direct OTA installation is only supported on Android. Please open the release page in your browser.',
      );
      return;
    }

    final currentApp = await checkCurrentApkVersion();
    final authority = '${currentApp.packageName}.ota_update_provider';
    final filename = destinationFilename ??
        config.destinationFilename ??
        '${config.githubRepo}-update.apk';

    final controller = StreamController<AppUpdateProgress>();

    try {
      yield const AppUpdateProgress(
        status: OtaDownloadStatus.downloading,
        percentage: 0,
        message: 'Initializing download...',
      );

      OtaUpdate()
          .execute(
        apkUrl,
        destinationFilename: filename,
        androidProviderAuthority: authority,
        sha256checksum: sha256Checksum,
      )
          .listen(
        (OtaEvent event) {
          switch (event.status) {
            case OtaStatus.DOWNLOADING:
              final percent = int.tryParse(event.value ?? '0') ?? 0;
              controller.add(
                AppUpdateProgress(
                  status: OtaDownloadStatus.downloading,
                  percentage: percent,
                  message: 'Downloading ($percent%)...',
                ),
              );
              break;
            case OtaStatus.INSTALLING:
              controller.add(
                const AppUpdateProgress(
                  status: OtaDownloadStatus.installing,
                  percentage: 100,
                  message: 'Launching installer...',
                ),
              );
              break;
            case OtaStatus.INSTALLATION_DONE:
              controller.add(
                const AppUpdateProgress(
                  status: OtaDownloadStatus.completed,
                  percentage: 100,
                  message: 'Installation completed.',
                ),
              );
              break;
            case OtaStatus.ALREADY_RUNNING_ERROR:
              controller.add(
                const AppUpdateProgress(
                  status: OtaDownloadStatus.alreadyRunning,
                  message: 'Download is already in progress.',
                ),
              );
              break;
            case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
              controller.add(
                const AppUpdateProgress(
                  status: OtaDownloadStatus.permissionNotGranted,
                  message:
                      'Permission to install unknown apps was denied. Please allow it in Android Settings.',
                ),
              );
              break;
            case OtaStatus.INTERNAL_ERROR:
              controller.add(
                AppUpdateProgress(
                  status: OtaDownloadStatus.internalError,
                  message: event.value ?? 'Internal error during update.',
                ),
              );
              break;
            case OtaStatus.DOWNLOAD_ERROR:
              controller.add(
                AppUpdateProgress(
                  status: OtaDownloadStatus.downloadError,
                  message: event.value ?? 'Failed to download APK file.',
                ),
              );
              break;
            case OtaStatus.CHECKSUM_ERROR:
              controller.add(
                const AppUpdateProgress(
                  status: OtaDownloadStatus.checksumError,
                  message: 'File checksum verification failed.',
                ),
              );
              break;
            case OtaStatus.CANCELED:
              controller.add(
                const AppUpdateProgress(
                  status: OtaDownloadStatus.idle,
                  message: 'Download was canceled.',
                ),
              );
              break;
            default:
              break;
          }
        },
        onError: (err) {
          controller.add(
            AppUpdateProgress(
              status: OtaDownloadStatus.internalError,
              message: 'Unexpected error: $err',
            ),
          );
        },
        onDone: () {
          controller.close();
        },
      );

      yield* controller.stream;
    } catch (e) {
      yield AppUpdateProgress(
        status: OtaDownloadStatus.internalError,
        message: 'Could not start update: $e',
      );
    }
  }

  /// Opens the release or download URL in the device's external browser.
  @override
  Future<bool> openReleaseInBrowser(String url) async {
    try {
      final target = url.isNotEmpty ? url : config.repositoryReleasesWebUrl;
      final uri = Uri.parse(target);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }
}
