import 'dart:convert';

import 'package:accountingmyanmar/core/update/app_update.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GithubAppUpdateService Tests', () {
    final config = UpdateConfig(
      githubOwner: 'thanwannahtun',
      githubRepo: 'accounting_myanmar',
    );

    final mockReleaseJson = jsonEncode({
      'tag_name': 'v1.0.1',
      'name': 'Accounting Myanmar v1.0.1',
      'body': '## Changes in v1.0.1\n- Bug fixes\n- OTA support',
      'published_at': '2026-10-20T10:00:00Z',
      'html_url':
          'https://github.com/thanwannahtun/accounting_myanmar/releases/tag/v1.0.1',
      'assets': [
        {
          'name': 'AccountingMyanmar-v1.0.1.apk',
          'size': 72000000,
          'browser_download_url':
              'https://github.com/thanwannahtun/accounting_myanmar/releases/download/v1.0.1/AccountingMyanmar-v1.0.1.apk',
        },
        {
          'name': 'source.zip',
          'size': 500000,
          'browser_download_url': 'https://github.com/.../source.zip',
        }
      ],
    });

    test('checkForVersionUpdate detects newer version when available', () async {
      final mockClient = MockClient((request) async {
        if (request.url == config.latestReleaseUri) {
          return http.Response(mockReleaseJson, 200, headers: {
            'content-type': 'application/json; charset=utf-8',
          });
        }
        return http.Response('Not Found', 404);
      });

      final storage = InMemoryUpdateStorage();

      final service = GithubAppUpdateService(
        config: config,
        httpClient: mockClient,
        storage: storage,
        customVersionProvider: () async => const AppVersionInfo(
          appName: 'Accounting Myanmar',
          packageName: 'com.thanwannahtun.business.accountingmyanmar.accountingmyanmar',
          version: '1.0.0',
          buildNumber: '2',
        ),
      );

      final result = await service.checkForVersionUpdate(force: true);

      expect(result.isSuccess, isTrue);
      expect(result.hasUpdate, isTrue);
      expect(result.latestVersion, 'v1.0.1');
      expect(result.releaseInfo, isNotNull);
      expect(result.releaseInfo!.apkFileName, 'AccountingMyanmar-v1.0.1.apk');
      expect(result.releaseInfo!.apkDownloadUrl, contains('v1.0.1.apk'));
      expect(result.releaseInfo!.formattedSize, contains('MB'));
      expect(await storage.getLastCheckTime(), isNotNull);
      expect(await storage.getCachedLatestVersion(), 'v1.0.1');
    });

    test('checkForVersionUpdate detects no update when current version is equal or newer', () async {
      final mockClient = MockClient((request) async {
        return http.Response(mockReleaseJson, 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final service = GithubAppUpdateService(
        config: config,
        httpClient: mockClient,
        customVersionProvider: () async => const AppVersionInfo(
          appName: 'Accounting Myanmar',
          packageName: 'com.thanwannahtun.business.accountingmyanmar.accountingmyanmar',
          version: '1.0.2',
          buildNumber: '1',
        ),
      );

      final result = await service.checkForVersionUpdate(force: true);

      expect(result.isSuccess, isTrue);
      expect(result.hasUpdate, isFalse);
    });

    test('shouldPerformPeriodicCheck respects 7 day interval', () async {
      final storage = InMemoryUpdateStorage();
      final service = GithubAppUpdateService(
        config: config,
        storage: storage,
      );

      // When never checked before
      expect(await service.shouldPerformPeriodicCheck(), isTrue);

      // When checked just now
      await storage.setLastCheckTime(DateTime.now());
      expect(await service.shouldPerformPeriodicCheck(), isFalse);

      // When checked 8 days ago
      await storage.setLastCheckTime(DateTime.now().subtract(const Duration(days: 8)));
      expect(await service.shouldPerformPeriodicCheck(), isTrue);
    });
  });
}
