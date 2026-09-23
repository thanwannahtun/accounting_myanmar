import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc_utils/bloc_status.dart';
import '../../data/models/journal_entry.dart';
import '../../data/models/journal_entry_line.dart';
import '../../data/repositories/journal/journal_entry_repository_interface.dart';
import 'journal_entry_state.dart';

class JournalEntryCubit extends Cubit<JournalEntryState> {
  final JournalEntryRepositoryInterface _journalRepository;

  JournalEntryCubit(this._journalRepository) : super(const JournalEntryState());

  Future<void> loadJournalEntries() async {
    emit(state.copyWith(status: BlocStatus.loading));
    try {
      final entries = await _journalRepository.getJournalEntries();
      emit(state.copyWith(
        status: BlocStatus.success,
        entries: entries,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> addJournalEntry({
    required String date,
    required String description,
    required List<JournalEntryLine> lines,
  }) async {
    final newEntry = JournalEntry(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      date: date.trim(),
      description: description.trim(),
      lines: lines,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    if (!newEntry.isBalanced) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: 'Cannot save: Debits and Credits must be balanced and greater than zero!',
      ));
      return;
    }

    try {
      await _journalRepository.addJournalEntry(newEntry);
      await loadJournalEntries();
    } catch (e) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: 'Failed to record journal entry: $e',
      ));
    }
  }

  Future<void> deleteJournalEntry(String id) async {
    try {
      await _journalRepository.deleteJournalEntry(id);
      await loadJournalEntries();
    } catch (e) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: 'Failed to delete transaction: $e',
      ));
    }
  }
}
