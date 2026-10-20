import 'package:equatable/equatable.dart';

/// Metadata describing a release obtained from a remote repository.
class UpdateInfo extends Equatable {
  final String tagName;
  final String releaseName;
  final String releaseNotes;
  final String apkDownloadUrl;
  final String apkFileName;
  final int apkSizeBytes;
  final DateTime? publishedAt;
  final String htmlUrl;

  const UpdateInfo({
    required this.tagName,
    required this.releaseName,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.apkFileName,
    required this.apkSizeBytes,
    required this.publishedAt,
    required this.htmlUrl,
  });

  /// Factory constructor to parse GitHub Releases JSON payload
  factory UpdateInfo.fromGitHubJson(
    Map<String, dynamic> json, {
    RegExp? apkAssetRegex,
  }) {
    final matcher = apkAssetRegex ?? RegExp(r'\.apk$', caseSensitive: false);
    final assets = (json['assets'] as List<dynamic>?) ?? [];

    Map<String, dynamic>? apkAsset;
    for (final item in assets) {
      if (item is Map<String, dynamic>) {
        final name = (item['name'] as String?) ?? '';
        if (matcher.hasMatch(name)) {
          apkAsset = item;
          break;
        }
      }
    }

    final apkUrl = apkAsset?['browser_download_url'] as String? ?? '';
    final apkName = apkAsset?['name'] as String? ?? '';
    final apkSize = (apkAsset?['size'] as num?)?.toInt() ?? 0;

    DateTime? publishedDate;
    if (json['published_at'] != null) {
      publishedDate = DateTime.tryParse(json['published_at'].toString());
    }

    return UpdateInfo(
      tagName: (json['tag_name'] as String?) ?? '',
      releaseName: (json['name'] as String?) ?? (json['tag_name'] as String? ?? ''),
      releaseNotes: (json['body'] as String?) ?? '',
      apkDownloadUrl: apkUrl,
      apkFileName: apkName,
      apkSizeBytes: apkSize,
      publishedAt: publishedDate,
      htmlUrl: (json['html_url'] as String?) ?? '',
    );
  }

  /// Human readable file size (e.g. "69.6 MB", "15.2 KB")
  String get formattedSize {
    if (apkSizeBytes <= 0) return '';
    const kb = 1024.0;
    const mb = kb * 1024.0;
    const gb = mb * 1024.0;

    if (apkSizeBytes >= gb) {
      return '${(apkSizeBytes / gb).toStringAsFixed(2)} GB';
    } else if (apkSizeBytes >= mb) {
      return '${(apkSizeBytes / mb).toStringAsFixed(1)} MB';
    } else if (apkSizeBytes >= kb) {
      return '${(apkSizeBytes / kb).toStringAsFixed(0)} KB';
    } else {
      return '$apkSizeBytes B';
    }
  }

  @override
  List<Object?> get props => [
        tagName,
        releaseName,
        releaseNotes,
        apkDownloadUrl,
        apkFileName,
        apkSizeBytes,
        publishedAt,
        htmlUrl,
      ];
}
