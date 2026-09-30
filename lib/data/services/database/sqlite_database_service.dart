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
  String? _dbPath;
  static bool _ffiInitialized = false;

  @override
  Future<void> init({String? dbPathOverride}) async {
    if (_db != null && _db!.isOpen) return;

    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      if (!_ffiInitialized) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        _ffiInitialized = true;
      }
    }

    final String dbPath;
    if (dbPathOverride != null) {
      dbPath = dbPathOverride;
    } else if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final appSupportDir = await getApplicationSupportDirectory();
      final dbFolder = Directory(p.join(appSupportDir.path, 'databases'));
      if (!await dbFolder.exists()) {
        await dbFolder.create(recursive: true);
      }
      dbPath = p.join(dbFolder.path, 'accounting_myanmar.db');

      // Check and migrate from legacy paths if target DB does not exist
      await _checkAndMigrateLegacyDatabase(dbPath, appSupportDir);
    } else {
      final defaultDatabasesPath = await getDatabasesPath();
      dbPath = p.join(defaultDatabasesPath, 'accounting_myanmar.db');
    }
    _dbPath = dbPath;

    _db = await openDatabase(
      dbPath,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onDowngrade: (db, oldVersion, newVersion) async {
        debugPrint(
          '[SqliteDatabaseService] Preserving database across version change: $oldVersion -> $newVersion',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE journal_entries ADD COLUMN remark TEXT',
          );
          await db.execute(
            "ALTER TABLE journal_entries ADD COLUMN status TEXT NOT NULL DEFAULT 'active'",
          );
          await db.execute(
            'ALTER TABLE journal_entries ADD COLUMN linked_transaction_id TEXT',
          );
        }
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
            remark TEXT,
            status TEXT NOT NULL DEFAULT 'active',
            linked_transaction_id TEXT,
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
      throw StateError(
        'SqliteDatabaseService has not been initialized. Call init() first.',
      );
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
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
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
      await txn.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
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

      await txn.insert('app_settings', {
        'key': 'sample_data_loaded',
        'value': 'true',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  @override
  Future<void> clearSampleData() async {
    await db.transaction((txn) async {
      // Remove default seeded transactions and accounts
      await txn.delete('journal_entry_lines');
      await txn.delete('journal_entries');
      await txn.delete('accounts');
      await txn.delete(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['sample_data_loaded'],
      );
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
    await db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> removeSetting(String key) async {
    await db.delete('app_settings', where: 'key = ?', whereArgs: [key]);
  }

  @override
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }

  /// Automatically searches for and safely migrates databases from legacy or
  /// alternate desktop support folders if the target database does not yet exist.
  Future<void> _checkAndMigrateLegacyDatabase(
    String targetDbPath,
    Directory appSupportDir,
  ) async {
    try {
      final targetFile = File(targetDbPath);
      if (await targetFile.exists() && (await targetFile.length()) > 0) {
        return; // Current target DB already exists with data
      }

      // Potential alternative/legacy locations
      final candidates = <String>[
        p.join(
          appSupportDir.parent.path,
          'accountingmyanmar',
          'databases',
          'accounting_myanmar.db',
        ),
        p.join(
          appSupportDir.parent.path,
          'Accounting Myanmar',
          'databases',
          'accounting_myanmar.db',
        ),
        p.join(appSupportDir.path, 'accounting_myanmar.db'),
      ];

      for (final candidate in candidates) {
        if (p.canonicalize(candidate) == p.canonicalize(targetDbPath)) continue;
        final candidateFile = File(candidate);
        if (await candidateFile.exists() &&
            (await candidateFile.length()) > 0) {
          debugPrint(
            '[SqliteDatabaseService] Migrating database from legacy path: $candidate -> $targetDbPath',
          );
          if (!await targetFile.parent.exists()) {
            await targetFile.parent.create(recursive: true);
          }
          await candidateFile.copy(targetDbPath);

          // Copy WAL/SHM companion files if present
          final wal = File('$candidate-wal');
          if (await wal.exists()) {
            await wal.copy('$targetDbPath-wal');
          }
          final shm = File('$candidate-shm');
          if (await shm.exists()) {
            await shm.copy('$targetDbPath-shm');
          }
          break;
        }
      }
    } catch (e) {
      debugPrint('[SqliteDatabaseService] Legacy DB migration check error: $e');
    }
  }

  @override
  Future<String> getDatabasePath() async {
    if (_dbPath != null) return _dbPath!;
    final defaultDatabasesPath = await getDatabasesPath();
    return p.join(defaultDatabasesPath, 'accounting_myanmar.db');
  }

  @override
  Future<int> getDatabaseSizeInBytes() async {
    final path = await getDatabasePath();
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  @override
  Future<List<int>> exportDatabaseBytes() async {
    // Flush write-ahead logging (WAL) into main database file
    if (_db != null && _db!.isOpen) {
      try {
        await _db!.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
      } catch (e) {
        debugPrint('[SqliteDatabaseService] wal_checkpoint note: $e');
      }
    }
    final path = await getDatabasePath();
    final file = File(path);
    if (!await file.exists()) {
      throw StateError('Database file does not exist at $path');
    }
    return await file.readAsBytes();
  }

  @override
  Future<void> importDatabaseFromBytes(List<int> bytes) async {
    // 1. Validation: Minimum 100 bytes and valid SQLite header
    if (bytes.length < 100) {
      throw const FormatException(
        'ဖိုင်အရွယ်အစား သေးငယ်လွန်းပါသည် (Invalid file size for SQLite database)',
      );
    }
    // SQLite header: "SQLite format 3\0"
    const sqliteHeader = [
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
    for (int i = 0; i < sqliteHeader.length; i++) {
      if (bytes[i] != sqliteHeader[i]) {
        throw const FormatException(
          'တရားဝင် SQLite Database ဖိုင် မဟုတ်ပါ (Not a valid SQLite 3 database header)',
        );
      }
    }

    final path = await getDatabasePath();
    final currentFile = File(path);
    final backupPath = '$path.rollback.bak';
    final backupFile = File(backupPath);

    // 2. Create rollback backup of current DB if it exists
    if (await currentFile.exists()) {
      await currentFile.copy(backupPath);
    }

    try {
      // 3. Close open database connection
      await close();

      // 4. Clean up any existing WAL / SHM files
      final walFile = File('$path-wal');
      if (await walFile.exists()) await walFile.delete();
      final shmFile = File('$path-shm');
      if (await shmFile.exists()) await shmFile.delete();

      // 5. Overwrite the database file with imported bytes
      if (!await currentFile.parent.exists()) {
        await currentFile.parent.create(recursive: true);
      }
      await currentFile.writeAsBytes(bytes, flush: true);

      // 6. Re-open database and verify integrity
      await init(dbPathOverride: path);

      // Verify we can read tables
      await _db!.rawQuery('SELECT 1 FROM accounts LIMIT 1');

      // 7. Cleanup rollback backup file on success
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    } catch (e) {
      // Rollback on failure
      debugPrint('[SqliteDatabaseService] Import failed, rolling back: $e');
      if (await backupFile.exists()) {
        await close();
        await backupFile.copy(path);
        await backupFile.delete();
        await init(dbPathOverride: path);
      }
      rethrow;
    }
  }
}
