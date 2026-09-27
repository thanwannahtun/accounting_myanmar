import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
    String? remark,
    bool isDraft = false,
  }) async {
    final status = isDraft ? 'draft' : 'posted';
    final newEntry = JournalEntry(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      date: date.trim(),
      description: description.trim(),
      remark: remark?.trim().isNotEmpty == true ? remark!.trim() : null,
      status: status,
      lines: lines,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    if (!isDraft && !newEntry.isBalanced) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage:
            'Cannot post: Debits and Credits must be balanced and greater than zero!',
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

  Future<void> reverseJournalEntry({
    required JournalEntry originalEntry,
    String? reversalDate,
    String? reason,
  }) async {
    if (!originalEntry.canReverse) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage:
            'Cannot reverse: This entry is already reversed or is a reversal entry.',
      ));
      return;
    }

    try {
      final now = DateTime.now();
      final date = reversalDate ?? DateFormat('yyyy-MM-dd').format(now);
      final newReversalId = 'rev_${now.millisecondsSinceEpoch}';

      // Swap debits and credits for all lines
      final invertedLines = originalEntry.lines.map((l) {
        return JournalEntryLine(
          id: 'l_${now.millisecondsSinceEpoch}_${l.id}',
          journalEntryId: newReversalId,
          accountId: l.accountId,
          debit: l.credit,
          credit: l.debit,
        );
      }).toList();

      final reversalEntry = JournalEntry(
        id: newReversalId,
        date: date,
        description:
            'Reversal of Entry #${originalEntry.id} - ${originalEntry.description}',
        remark: reason?.trim().isNotEmpty == true
            ? reason!.trim()
            : 'Reversal entry for #${originalEntry.id}',
        status: 'reversal',
        linkedTransactionId: originalEntry.id,
        lines: invertedLines,
        createdAt: now.millisecondsSinceEpoch,
      );

      final updatedOriginal = originalEntry.copyWith(
        status: 'reversed',
        linkedTransactionId: newReversalId,
      );

      await _journalRepository.addJournalEntry(reversalEntry);
      await _journalRepository.updateJournalEntry(updatedOriginal);

      await loadJournalEntries();
    } catch (e) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: 'Failed to reverse journal entry: $e',
      ));
    }
  }

  Future<void> postDraftEntry(JournalEntry draftEntry) async {
    if (!draftEntry.isDraft) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: 'Only draft entries can be posted.',
      ));
      return;
    }

    if (!draftEntry.isBalanced) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage:
            'Cannot post draft: Debits and Credits must be balanced and greater than zero!',
      ));
      return;
    }

    try {
      final postedEntry = draftEntry.copyWith(status: 'posted');
      await _journalRepository.updateJournalEntry(postedEntry);
      await loadJournalEntries();
    } catch (e) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: 'Failed to post draft entry: $e',
      ));
    }
  }

  Future<void> updateJournalEntry({
    required String id,
    required String date,
    required String description,
    required List<JournalEntryLine> lines,
    String? remark,
    bool isDraft = true,
  }) async {
    final existing = state.entries.where((e) => e.id == id).firstOrNull;
    if (existing == null) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: 'Journal entry not found.',
      ));
      return;
    }

    if (!existing.canEdit) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: 'Security & Standard Guard: Only draft entries can be edited.',
      ));
      return;
    }

    final updated = existing.copyWith(
      date: date.trim(),
      description: description.trim(),
      remark: remark?.trim().isNotEmpty == true ? remark!.trim() : null,
      status: isDraft ? 'draft' : 'posted',
      lines: lines,
    );

    if (!isDraft && !updated.isBalanced) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage:
            'Cannot post: Debits and Credits must be balanced and greater than zero!',
      ));
      return;
    }

    try {
      await _journalRepository.updateJournalEntry(updated);
      await loadJournalEntries();
    } catch (e) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: 'Failed to update journal entry: $e',
      ));
    }
  }

  void setLifecycleFilter(String filter) {
    emit(state.copyWith(lifecycleFilter: filter, pageLimit: 20));
  }

  void setSortOrder(bool isAscending) {
    emit(state.copyWith(isAscending: isAscending, pageLimit: 20));
  }

  void setDateRange(String? start, String? end) {
    emit(state.copyWith(startDate: start, endDate: end, pageLimit: 20));
  }

  void clearDateRange() {
    emit(state.copyWith(clearDates: true, pageLimit: 20));
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query, pageLimit: 20));
  }

  void loadMoreEntries() {
    if (!state.hasMore) return;
    emit(state.copyWith(pageLimit: state.pageLimit + 20));
  }

  Future<void> deleteJournalEntry(String id) async {
    final target = state.entries.where((e) => e.id == id).firstOrNull;
    if (target != null && !target.isDraft) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage:
            'Security & Standard Guard: Posted entries cannot be deleted. Use Reverse Entry instead.',
      ));
      return;
    }

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
