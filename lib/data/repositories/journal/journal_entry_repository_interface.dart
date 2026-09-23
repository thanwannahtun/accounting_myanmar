import '../../models/journal_entry.dart';

abstract class JournalEntryRepositoryInterface {
  Future<List<JournalEntry>> getJournalEntries();
  Future<JournalEntry?> getJournalEntryById(String id);
  Future<void> addJournalEntry(JournalEntry entry);
  Future<void> updateJournalEntry(JournalEntry entry);
  Future<void> deleteJournalEntry(String id);
}
