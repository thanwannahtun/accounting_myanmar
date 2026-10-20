import 'package:accountingmyanmar/core/update/services/version_comparator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VersionComparator Tests', () {
    test('Standard semver comparison', () {
      expect(VersionComparator.isNewer('1.0.0', '1.0.1'), isTrue);
      expect(VersionComparator.isNewer('1.0.1', '1.0.0'), isFalse);
      expect(VersionComparator.isNewer('1.0.0', '1.0.0'), isFalse);
      expect(VersionComparator.isNewer('1.0.0', '1.1.0'), isTrue);
      expect(VersionComparator.isNewer('1.9.9', '2.0.0'), isTrue);
      expect(VersionComparator.isNewer('2.0.0', '1.9.9'), isFalse);
    });

    test('Handles "v" prefix gracefully', () {
      expect(VersionComparator.isNewer('1.0.0', 'v1.0.1'), isTrue);
      expect(VersionComparator.isNewer('v1.0.0', '1.0.1'), isTrue);
      expect(VersionComparator.isNewer('v1.0.0', 'v1.0.0'), isFalse);
    });

    test('Handles short tags like v1 or v2', () {
      expect(VersionComparator.isNewer('1.0.0', 'v2'), isTrue);
      expect(VersionComparator.isNewer('1.0.0', 'v1'), isFalse);
      expect(VersionComparator.isNewer('0.9.0', 'v1'), isTrue);
    });

    test('Handles build numbers (+)', () {
      expect(VersionComparator.isNewer('1.0.0+1', '1.0.0+2'), isTrue);
      expect(VersionComparator.isNewer('1.0.0+2', '1.0.0+1'), isFalse);
      expect(VersionComparator.isNewer('1.0.0+2', '1.0.0+2'), isFalse);
      expect(VersionComparator.isNewer('1.0.0+9', '1.0.1+1'), isTrue);
    });

    test('Handles prerelease tags (-beta)', () {
      expect(VersionComparator.isNewer('1.0.0-beta.1', '1.0.1'), isTrue);
      expect(VersionComparator.isNewer('1.0.0', '1.0.1-rc'), isTrue);
    });
  });
}
