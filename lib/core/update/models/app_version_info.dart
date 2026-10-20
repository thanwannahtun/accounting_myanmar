import 'package:equatable/equatable.dart';

/// Clean model representing the current running application version.
class AppVersionInfo extends Equatable {
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;

  const AppVersionInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });

  /// Example: "1.0.0+2"
  String get versionWithBuild =>
      buildNumber.isNotEmpty ? '$version+$buildNumber' : version;

  /// Example: "v1.0.0"
  String get displayVersion => 'v$version';

  /// Example: "v1.0.0 (Build 2)"
  String get fullDisplay =>
      buildNumber.isNotEmpty ? 'v$version (Build $buildNumber)' : 'v$version';

  /// Fallback empty instance
  static const empty = AppVersionInfo(
    appName: '',
    packageName: '',
    version: '1.0.0',
    buildNumber: '1',
  );

  @override
  List<Object?> get props => [appName, packageName, version, buildNumber];

  @override
  String toString() => '$appName $displayVersion (+$buildNumber)';
}
