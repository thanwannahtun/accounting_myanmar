import 'package:equatable/equatable.dart';

/// Configuration options for the version update lifecycle.
///
/// Decouples repository details, file matching rules, and check frequencies
/// so the service can be reused across any Flutter project.
class UpdateConfig extends Equatable {
  /// GitHub repository owner (e.g., 'thanwannahtun')
  final String githubOwner;

  /// GitHub repository name (e.g., 'accounting_myanmar')
  final String githubRepo;

  /// Regular expression to match the APK asset inside GitHub release assets.
  /// Defaults to matching any file ending in `.apk`.
  final RegExp apkAssetRegex;

  /// Interval for periodic automatic background checks (defaults to 7 days).
  final Duration checkInterval;

  /// Whether to consider pre-release GitHub releases when checking for updates.
  final bool allowPrereleases;

  /// Custom destination filename for saving the downloaded APK locally.
  final String? destinationFilename;

  /// Optional custom GitHub API base URL (defaults to `https://api.github.com`).
  final String apiBaseUrl;

  UpdateConfig({
    required this.githubOwner,
    required this.githubRepo,
    RegExp? apkAssetRegex,
    this.checkInterval = const Duration(days: 7),
    this.allowPrereleases = false,
    this.destinationFilename,
    this.apiBaseUrl = 'https://api.github.com',
  }) : apkAssetRegex =
            apkAssetRegex ?? RegExp(r'\.apk$', caseSensitive: false);

  /// URL for the GitHub latest release API endpoint
  Uri get latestReleaseUri => Uri.parse(
        '$apiBaseUrl/repos/$githubOwner/$githubRepo/releases/latest',
      );

  /// Web release page URL (fallback or browser viewing)
  String get repositoryReleasesWebUrl =>
      'https://github.com/$githubOwner/$githubRepo/releases';

  @override
  List<Object?> get props => [
        githubOwner,
        githubRepo,
        apkAssetRegex.pattern,
        checkInterval,
        allowPrereleases,
        destinationFilename,
        apiBaseUrl,
      ];
}
