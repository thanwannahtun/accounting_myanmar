import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:accountingmyanmar/core/constants/account_types.dart';
import 'package:accountingmyanmar/core/constants/seed_data.dart';
import 'package:accountingmyanmar/data/models/account.dart';
import 'package:accountingmyanmar/data/services/database/sqlite_database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await SqliteDatabaseService.instance.close();
  });

  test('SqliteDatabaseService initializes on Windows FFI and performs CRUD', () async {
    await SqliteDatabaseService.instance.init(dbPathOverride: inMemoryDatabasePath);

    // 1. Initially empty
    expect(await SqliteDatabaseService.instance.hasData(), isFalse);

    // 2. Insert account
    const testAccount = Account(
      id: 'acc_windows_test',
      code: '9999',
      name: 'Windows FFI Test Account',
      type: AccountTypes.asset,
    );
    await SqliteDatabaseService.instance.insertAccount(testAccount);

    final fetchedAccount = await SqliteDatabaseService.instance.getAccountById('acc_windows_test');
    expect(fetchedAccount, isNotNull);
    expect(fetchedAccount!.name, 'Windows FFI Test Account');

    // 3. Seed data
    await SqliteDatabaseService.instance.seedInitialData(
      SeedData.initialAccounts,
      SeedData.initialTransactions,
    );

    expect(await SqliteDatabaseService.instance.hasData(), isTrue);

    final allAccounts = await SqliteDatabaseService.instance.getAllAccounts();
    expect(allAccounts.length >= 13, isTrue);

    final allEntries = await SqliteDatabaseService.instance.getAllJournalEntries();
    expect(allEntries.length, 15);

    // 4. App settings store
    await SqliteDatabaseService.instance.setSetting('test_key', 'test_val');
    final settingVal = await SqliteDatabaseService.instance.getSetting('test_key');
    expect(settingVal, 'test_val');
  });
}
