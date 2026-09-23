import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../models/account.dart';
import '../../models/journal_entry.dart';
import '../../models/journal_entry_line.dart';
import 'database_service_interface.dart';

class SqliteDatabaseService implements DatabaseServiceInterface {
  static final SqliteDatabaseService instance = SqliteDatabaseService._();
  SqliteDatabaseService._();

  Database? _db;

  @override
  Future<void> init({String? dbPathOverride}) async {
    if (_db != null && _db!.isOpen) return;

    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final String dbPath;
    if (dbPathOverride != null) {
      dbPath = dbPathOverride;
    } else if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final appSupportDir = await getApplicationSupportDirectory();
      final dbFolder = Directory(p.join(appSupportDir.path, 'databases'));
      if (!await dbFolder.exists()) {
        await dbFolder.create(recursive: true);
      }
      dbPath = p.join(dbFolder.path, 'accounting_myanmar.db');
    } else {
      final defaultDatabasesPath = await getDatabasesPath();
      dbPath = p.join(defaultDatabasesPath, 'accounting_myanmar.db');
    }

    _db = await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE accounts (
            id TEXT PRIMARY KEY,
            code TEXT NOT NULL UNIQUE,
            name TEXT NOT NULL,
            type TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE journal_entries (
            id TEXT PRIMARY KEY,
            date TEXT NOT NULL,
            description TEXT NOT NULL,
            created_at INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE journal_entry_lines (
            id TEXT PRIMARY KEY,
            journal_entry_id TEXT NOT NULL,
            account_id TEXT NOT NULL,
            debit REAL NOT NULL DEFAULT 0.0,
            credit REAL NOT NULL DEFAULT 0.0,
            FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON DELETE CASCADE,
            FOREIGN KEY (account_id) REFERENCES accounts(id)
          )
        ''');

        await db.execute('''
          CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Database get db {
    if (_db == null) {
      throw StateError('SqliteDatabaseService has not been initialized. Call init() first.');
    }
    return _db!;
  }

  @override
  Future<List<Account>> getAllAccounts() async {
    final rows = await db.query('accounts', orderBy: 'code ASC');
    return rows.map((r) => Account.fromMap(r)).toList();
  }

  @override
  Future<Account?> getAccountById(String id) async {
    final rows = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Account.fromMap(rows.first);
  }

  @override
  Future<void> insertAccount(Account account) async {
    await db.insert(
      'accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateAccount(Account account) async {
    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  @override
  Future<void> deleteAccount(String id) async {
    await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<JournalEntry>> getAllJournalEntries() async {
    final entryRows = await db.query(
      'journal_entries',
      orderBy: 'date ASC, created_at ASC',
    );
    final lineRows = await db.query('journal_entry_lines');

    final linesByEntryId = <String, List<JournalEntryLine>>{};
    for (final lr in lineRows) {
      final line = JournalEntryLine.fromMap(lr);
      linesByEntryId.putIfAbsent(line.journalEntryId, () => []).add(line);
    }

    return entryRows.map((er) {
      final id = er['id'] as String;
      final lines = linesByEntryId[id] ?? [];
      return JournalEntry.fromMap(er, lines);
    }).toList();
  }

  @override
  Future<JournalEntry?> getJournalEntryById(String id) async {
    final entryRows = await db.query(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (entryRows.isEmpty) return null;

    final lineRows = await db.query(
      'journal_entry_lines',
      where: 'journal_entry_id = ?',
      whereArgs: [id],
    );

    final lines = lineRows.map((lr) => JournalEntryLine.fromMap(lr)).toList();
    return JournalEntry.fromMap(entryRows.first, lines);
  }

  @override
  Future<void> insertJournalEntry(JournalEntry entry) async {
    await db.transaction((txn) async {
      await txn.insert(
        'journal_entries',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final line in entry.lines) {
        await txn.insert(
          'journal_entry_lines',
          line.copyWith(journalEntryId: entry.id).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<void> updateJournalEntry(JournalEntry entry) async {
    await db.transaction((txn) async {
      await txn.update(
        'journal_entries',
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );

      await txn.delete(
        'journal_entry_lines',
        where: 'journal_entry_id = ?',
        whereArgs: [entry.id],
      );

      for (final line in entry.lines) {
        await txn.insert(
          'journal_entry_lines',
          line.copyWith(journalEntryId: entry.id).toMap(),
        );
      }
    });
  }

  @override
  Future<void> deleteJournalEntry(String id) async {
    await db.transaction((txn) async {
      await txn.delete(
        'journal_entry_lines',
        where: 'journal_entry_id = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'journal_entries',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<bool> hasData() async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM accounts'),
    );
    return (count ?? 0) > 0;
  }

  @override
  Future<void> seedInitialData(
    List<Account> accounts,
    List<JournalEntry> entries,
  ) async {
    await db.transaction((txn) async {
      for (final acc in accounts) {
        await txn.insert(
          'accounts',
          acc.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final entry in entries) {
        await txn.insert(
          'journal_entries',
          entry.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        for (final line in entry.lines) {
          await txn.insert(
            'journal_entry_lines',
            line.copyWith(journalEntryId: entry.id).toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      await txn.insert(
        'app_settings',
        {'key': 'sample_data_loaded', 'value': 'true'},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  @override
  Future<void> clearSampleData() async {
    await db.transaction((txn) async {
      // Remove default seeded transactions and accounts
      await txn.delete('journal_entry_lines');
      await txn.delete('journal_entries');
      await txn.delete('accounts');
      await txn.delete('app_settings', where: 'key = ?', whereArgs: ['sample_data_loaded']);
    });
  }

  @override
  Future<void> clearAllData() async {
    await db.transaction((txn) async {
      await txn.delete('journal_entry_lines');
      await txn.delete('journal_entries');
      await txn.delete('accounts');
      await txn.delete('app_settings');
    });
  }

  @override
  Future<String?> getSetting(String key) async {
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<void> setSetting(String key, String value) async {
    await db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> removeSetting(String key) async {
    await db.delete(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  @override
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
