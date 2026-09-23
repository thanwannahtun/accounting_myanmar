import '../../models/journal_entry.dart';
import '../../services/database/database_service_interface.dart';
import 'journal_entry_repository_interface.dart';

class JournalEntryLocalRepository implements JournalEntryRepositoryInterface {
  final DatabaseServiceInterface _databaseService;

  JournalEntryLocalRepository(this._databaseService);

  @override
  Future<List<JournalEntry>> getJournalEntries() {
    return _databaseService.getAllJournalEntries();
  }

  @override
  Future<JournalEntry?> getJournalEntryById(String id) {
    return _databaseService.getJournalEntryById(id);
  }

  @override
  Future<void> addJournalEntry(JournalEntry entry) {
    return _databaseService.insertJournalEntry(entry);
  }

  @override
  Future<void> updateJournalEntry(JournalEntry entry) {
    return _databaseService.updateJournalEntry(entry);
  }

  @override
  Future<void> deleteJournalEntry(String id) {
    return _databaseService.deleteJournalEntry(id);
  }
}
