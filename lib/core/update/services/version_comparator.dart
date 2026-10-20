/// Pure semantic version comparator for app versions and release tags.
///
/// Handles common formats:
/// - "v1.2.3" vs "1.2.3"
/// - "1.0.0+2" vs "1.0.0+1"
/// - "v1" vs "v1.0.0"
/// - "1.0.0-beta.1"
class VersionComparator {
  const VersionComparator._();

  /// Returns true if [remoteVersion] is strictly newer than [currentVersion].
  static bool isNewer(String currentVersion, String remoteVersion) {
    return compare(currentVersion, remoteVersion) < 0;
  }

  /// Compares [v1] and [v2].
  ///
  /// Returns:
  /// - negative integer if v1 < v2 (v2 is newer)
  /// - zero if v1 == v2
  /// - positive integer if v1 > v2 (v1 is newer)
  static int compare(String v1, String v2) {
    final parsed1 = _parse(v1);
    final parsed2 = _parse(v2);

    // Compare Major, Minor, Patch
    for (var i = 0; i < 3; i++) {
      if (parsed1.numbers[i] != parsed2.numbers[i]) {
        return parsed1.numbers[i].compareTo(parsed2.numbers[i]);
      }
    }

    // If base versions are equal, compare build numbers if present
    if (parsed1.buildNumber != null && parsed2.buildNumber != null) {
      return parsed1.buildNumber!.compareTo(parsed2.buildNumber!);
    } else if (parsed1.buildNumber == null && parsed2.buildNumber != null) {
      // Version with a build number is generally considered newer than one without
      return -1;
    } else if (parsed1.buildNumber != null && parsed2.buildNumber == null) {
      return 1;
    }

    return 0;
  }

  static _ParsedVersion _parse(String raw) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('v') || cleaned.startsWith('V')) {
      cleaned = cleaned.substring(1);
    }

    int? buildNumber;
    if (cleaned.contains('+')) {
      final parts = cleaned.split('+');
      cleaned = parts[0];
      if (parts.length > 1) {
        buildNumber = int.tryParse(parts[1]);
      }
    }

    // Strip pre-release suffixes like -beta, -rc1
    if (cleaned.contains('-')) {
      cleaned = cleaned.split('-')[0];
    }

    final segments = cleaned.split('.');
    final numbers = <int>[0, 0, 0];

    for (var i = 0; i < 3; i++) {
      if (i < segments.length) {
        numbers[i] = int.tryParse(segments[i]) ?? 0;
      } else {
        numbers[i] = 0;
      }
    }

    return _ParsedVersion(numbers: numbers, buildNumber: buildNumber);
  }
}

class _ParsedVersion {
  final List<int> numbers; // [major, minor, patch]
  final int? buildNumber;

  const _ParsedVersion({required this.numbers, this.buildNumber});
}
