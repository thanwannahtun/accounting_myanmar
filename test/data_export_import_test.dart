import 'dart:io';

import 'package:accountingmyanmar/data/models/account.dart';
import 'package:accountingmyanmar/data/models/journal_entry.dart';
import 'package:accountingmyanmar/data/models/journal_entry_line.dart';
import 'package:accountingmyanmar/data/models/print_config.dart';
import 'package:accountingmyanmar/data/repositories/account/account_local_repository.dart';
import 'package:accountingmyanmar/data/repositories/journal/journal_entry_local_repository.dart';
import 'package:accountingmyanmar/data/repositories/settings/settings_local_repository.dart';
import 'package:accountingmyanmar/data/services/database/sqlite_database_service.dart';
import 'package:accountingmyanmar/data/services/export/export_service.dart';
import 'package:accountingmyanmar/logic/settings/settings_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String testDbPath;
  late SqliteDatabaseService dbService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'accounting_export_import_test_',
    );
    testDbPath = '${tempDir.path}/test_accounting.db';
    dbService = SqliteDatabaseService.instance;
    await dbService.close();
    await dbService.init(dbPathOverride: testDbPath);
  });

  tearDown(() async {
    await dbService.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('SQLite Database Export & Import Unit Tests', () {
    test('exportDatabaseBytes exports valid SQLite 3 database bytes with correct header', () async {
      // 1. Insert a test account
      await dbService.insertAccount(
        const Account(
          id: 'acc_test_1',
          code: '1010',
          name: 'Petty Cash',
          type: 'Asset',
        ),
      );

      // 2. Export bytes
      final bytes = await dbService.exportDatabaseBytes();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThanOrEqualTo(100));

      // 3. Verify standard SQLite 3 magic header ("SQLite format 3\0")
      const expectedHeader = [
        0x53,
        0x51,
        0x4c,
        0x69,
        0x74,
        0x65,
        0x20,
        0x66,
        0x6f,
        0x72,
        0x6d,
        0x61,
        0x74,
        0x20,
        0x33,
        0x00,
      ];
      expect(bytes.take(16).toList(), equals(expectedHeader));

      // 4. Verify file size
      final size = await dbService.getDatabaseSizeInBytes();
      expect(size, equals(bytes.length));
    });

    test('importDatabaseFromBytes rejects invalid or corrupted bytes with FormatException', () async {
      // Too short
      expect(
        () => dbService.importDatabaseFromBytes([1, 2, 3]),
        throwsA(isA<FormatException>()),
      );

      // Corrupted header
      final dummyBytes = List<int>.filled(200, 0);
      expect(
        () => dbService.importDatabaseFromBytes(dummyBytes),
        throwsA(isA<FormatException>()),
      );
    });

    test('importDatabaseFromBytes successfully restores a valid SQLite database backup', () async {
      // 1. Insert account in original DB
      await dbService.insertAccount(
        const Account(
          id: 'acc_original',
          code: '1001',
          name: 'Cash on Hand',
          type: 'Asset',
        ),
      );
      final backupBytes = await dbService.exportDatabaseBytes();

      // 2. Wipe DB
      await dbService.clearAllData();
      final accountsAfterClear = await dbService.getAllAccounts();
      expect(accountsAfterClear, isEmpty);

      // 3. Restore from exported bytes
      await dbService.importDatabaseFromBytes(backupBytes);

      // 4. Verify restored account
      final restoredAccounts = await dbService.getAllAccounts();
      expect(restoredAccounts.length, equals(1));
      expect(restoredAccounts.first.code, equals('1001'));
      expect(restoredAccounts.first.name, equals('Cash on Hand'));
    });
  });

  group('CSV Export & Import Tests', () {
    test(
      'parseCsv handles standard RFC 4180 CSV with quotes, commas, and CRLF',
      () {
        const csv =
            'Code,Name,Type\r\n'
            '1000,Cash,Asset\r\n'
            '2000,"Trade Payable, Local",Liability\r\n'
            '3000,"Owner\'s ""Equity""",Equity\r\n';

        final rows = ExportService.instance.parseCsv(csv);
        expect(rows.length, equals(4));
        expect(rows[0], equals(['Code', 'Name', 'Type']));
        expect(rows[1], equals(['1000', 'Cash', 'Asset']));
        expect(rows[2], equals(['2000', 'Trade Payable, Local', 'Liability']));
        expect(rows[3], equals(['3000', 'Owner\'s "Equity"', 'Equity']));
      },
    );

    test(
      'detectCsvType correctly differentiates Accounts vs Journal Entries',
      () {
        final accountRows = [
          ['Code', 'Name', 'Type'],
          ['1000', 'Cash', 'Asset'],
        ];
        expect(
          ExportService.instance.detectCsvType(accountRows),
          equals(CsvImportType.accounts),
        );

        final journalRows = [
          ['Date', 'Description', 'Account Code', 'Debit', 'Credit'],
          ['2026-09-30', 'Sales Revenue', '1000', '50000', '0'],
        ];
        expect(
          ExportService.instance.detectCsvType(journalRows),
          equals(CsvImportType.journalEntries),
        );

        final unknownRows = [
          ['Foo', 'Bar'],
          ['1', '2'],
        ];
        expect(
          ExportService.instance.detectCsvType(unknownRows),
          equals(CsvImportType.unknown),
        );
      },
    );

    test(
      'importCsvContent imports Chart of Accounts CSV successfully into SQLite',
      () async {
        const accountsCsv = '''
Code,Name,Type
1010,Bank Account KBZ,Asset
2010,Accounts Payable Vendor,Liability
4010,Service Income,Revenue
5010,Office Rental Expense,Expense
''';

        final result = await ExportService.instance.importCsvContent(
          accountsCsv,
          dbService: dbService,
        );

        expect(result.type, equals(CsvImportType.accounts));
        expect(result.importedAccountsCount, equals(4));

        final accountsInDb = await dbService.getAllAccounts();
        expect(accountsInDb.length, equals(4));
        expect(accountsInDb.any((a) => a.code == '1010'), isTrue);
        expect(accountsInDb.any((a) => a.code == '2010'), isTrue);
        expect(accountsInDb.any((a) => a.code == '4010'), isTrue);
        expect(accountsInDb.any((a) => a.code == '5010'), isTrue);
      },
    );

    test(
      'importCsvContent imports Journal Entries CSV successfully into SQLite',
      () async {
        const journalCsv = '''
Date,Description,Account Code,Debit,Credit,Remark
2026-09-30,Office Rent Payment,5010,500000,0,September Rent
2026-09-30,Office Rent Payment,1010,0,500000,Paid via KBZ Bank
''';

        final result = await ExportService.instance.importCsvContent(
          journalCsv,
          dbService: dbService,
        );

        expect(result.type, equals(CsvImportType.journalEntries));
        expect(result.importedTransactionsCount, equals(1));

        final entries = await dbService.getAllJournalEntries();
        expect(entries.length, equals(1));
        final entry = entries.first;
        expect(entry.description, equals('Office Rent Payment'));
        expect(entry.lines.length, equals(2));
        expect(entry.lines.first.debit, equals(500000.0));
        expect(entry.lines.last.credit, equals(500000.0));
      },
    );

    test('exportAccountsToCsv and exportJournalEntriesToCsv produce valid UTF-8 BOM CSVs', () async {
      final accounts = [
        const Account(
          id: 'a1',
          code: '1000',
          name: 'ငွေသား (Cash)',
          type: 'Asset',
        ),
      ];
      final entries = [
        JournalEntry(
          id: 'tx_1',
          date: '2026-09-30',
          description: 'အဖွင့်စာရင်း (Opening Entry)',
          lines: const [
            JournalEntryLine(
              id: 'l1',
              journalEntryId: 'tx_1',
              accountId: 'a1',
              debit: 100000,
              credit: 0,
            ),
          ],
        ),
      ];

      final accExport = await ExportService.instance.exportAccountsToCsv(
        accounts: accounts,
        printConfig: const PrintConfig(companyName: 'မင်္ဂလာ ကုန်သွယ်ရေး'),
      );
      expect(accExport.csvContent, contains('ငွေသား (Cash)'));
      expect(
        accExport.bytesWithBom.take(3).toList(),
        equals([0xEF, 0xBB, 0xBF]),
      );

      final entryExport = await ExportService.instance
          .exportJournalEntriesToCsv(
            entries: entries,
            accounts: accounts,
            printConfig: const PrintConfig(companyName: 'မင်္ဂလာ ကုန်သွယ်ရေး'),
          );
      expect(entryExport.csvContent, contains('အဖွင့်စာရင်း (Opening Entry)'));
      expect(
        entryExport.bytesWithBom.take(3).toList(),
        equals([0xEF, 0xBB, 0xBF]),
      );

      // Clean up generated test files
      if (File(accExport.filePath).existsSync()) {
        File(accExport.filePath).deleteSync();
      }
      if (File(entryExport.filePath).existsSync()) {
        File(entryExport.filePath).deleteSync();
      }
    });
  });

  group('Data Persistence on App Version Update Tests', () {
    test('SettingsCubit guarantees isFirstTime is false when database has existing data or updated version', () async {
      // 1. Seed database with account
      await dbService.insertAccount(
        const Account(
          id: 'acc_persist',
          code: '1000',
          name: 'Cash',
          type: 'Asset',
        ),
      );
      // Mark version in db
      await dbService.setSetting('last_app_version', '1.0.0+1');

      final settingsRepo = SettingsLocalRepository(dbService);
      final accountRepo = AccountLocalRepository(dbService);
      final journalRepo = JournalEntryLocalRepository(dbService);

      final cubit = SettingsCubit(
        settingsRepository: settingsRepo,
        accountRepository: accountRepo,
        journalRepository: journalRepo,
      );

      await cubit.init();

      // 2. isFirstTime MUST be false (data preserved, never resets to fresh app state)
      expect(cubit.state.isFirstTime, isFalse);
      expect(cubit.state.hasData, isTrue);
      expect(cubit.state.totalAccountsCount, equals(1));

      // 3. New version tag is persisted into database
      final recordedVersion = await dbService.getSetting('last_app_version');
      expect(recordedVersion, equals(SettingsCubit.currentAppVersion));

      // 4. first_time_prompted is also permanently set in SQLite
      final firstTimePrompted = await dbService.getSetting(
        'first_time_prompted',
      );
      expect(firstTimePrompted, equals('true'));

      await cubit.close();
    });
  });
}
