import '../../models/account.dart';
import '../../models/journal_entry.dart';

abstract class DatabaseServiceInterface {
  Future<void> init({String? dbPathOverride});
  Future<void> close();

  // Accounts
  Future<List<Account>> getAllAccounts();
  Future<Account?> getAccountById(String id);
  Future<void> insertAccount(Account account);
  Future<void> updateAccount(Account account);
  Future<void> deleteAccount(String id);

  // Journal Entries
  Future<List<JournalEntry>> getAllJournalEntries();
  Future<JournalEntry?> getJournalEntryById(String id);
  Future<void> insertJournalEntry(JournalEntry entry);
  Future<void> updateJournalEntry(JournalEntry entry);
  Future<void> deleteJournalEntry(String id);

  // Seeding and storage management
  Future<bool> hasData();
  Future<void> seedInitialData(
    List<Account> accounts,
    List<JournalEntry> entries,
  );
  Future<void> clearSampleData();
  Future<void> clearAllData();

  // Settings store
  Future<String?> getSetting(String key);
  Future<void> setSetting(String key, String value);
  Future<void> removeSetting(String key);

  // Database file backup & restore
  Future<String> getDatabasePath();
  Future<int> getDatabaseSizeInBytes();
  Future<List<int>> exportDatabaseBytes();
  Future<void> importDatabaseFromBytes(List<int> bytes);
}
