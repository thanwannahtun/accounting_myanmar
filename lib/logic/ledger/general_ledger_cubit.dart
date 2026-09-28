import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/bloc_utils/bloc_status.dart';
import '../../core/constants/account_types.dart';
import '../../data/models/account.dart';
import '../../data/models/financial_report.dart';
import '../../data/models/journal_entry.dart';
import '../../data/models/print_config.dart';
import '../../data/services/export/export_service.dart';
import '../../data/services/print/print_service.dart';
import 'general_ledger_state.dart';

class GeneralLedgerCubit extends Cubit<GeneralLedgerState> {
  final ExportService _exportService;
  final PrintService _printService;

  GeneralLedgerCubit({ExportService? exportService, PrintService? printService})
    : _exportService = exportService ?? ExportService.instance,
      _printService = printService ?? PrintService.instance,
      super(const GeneralLedgerState());

  void selectAccount({
    required Account account,
    required List<JournalEntry> transactions,
  }) {
    emit(state.copyWith(status: BlocStatus.loading, selectedAccount: account));
    try {
      final entries = _computeLedgerEntries(account, transactions);
      final endingBalance = entries.isNotEmpty ? entries.last.balance : 0.0;
      emit(
        state.copyWith(
          status: BlocStatus.success,
          selectedAccount: account,
          entries: entries,
          endingBalance: endingBalance,
          pageLimit: 20,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BlocStatus.failure,
          errorMessage: 'Failed to compute ledger entries: $e',
        ),
      );
    }
  }

  void setDateFilterMode(String mode) {
    if (mode == 'all') {
      emit(
        state.copyWith(dateFilterMode: 'all', clearDates: true, pageLimit: 20),
      );
      return;
    }

    final now = DateTime.now();
    if (mode == 'this_month') {
      final start = DateFormat('yyyy-MM-01').format(now);
      final lastDay = DateTime(now.year, now.month + 1, 0);
      final end = DateFormat('yyyy-MM-dd').format(lastDay);
      emit(
        state.copyWith(
          dateFilterMode: 'this_month',
          startDate: start,
          endDate: end,
          pageLimit: 20,
        ),
      );
      return;
    }

    if (mode == 'this_year') {
      final start = '${now.year}-01-01';
      final end = '${now.year}-12-31';
      emit(
        state.copyWith(
          dateFilterMode: 'this_year',
          startDate: start,
          endDate: end,
          pageLimit: 20,
        ),
      );
      return;
    }
  }

  void setCustomDateRange(String start, String end) {
    emit(
      state.copyWith(
        dateFilterMode: 'custom',
        startDate: start,
        endDate: end,
        pageLimit: 20,
      ),
    );
  }

  void clearDateFilter() {
    emit(
      state.copyWith(dateFilterMode: 'all', clearDates: true, pageLimit: 20),
    );
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query, pageLimit: 20));
  }

  void loadMoreEntries() {
    if (!state.hasMore) return;
    emit(state.copyWith(pageLimit: state.pageLimit + 20));
  }

  void refresh({
    required List<Account> accounts,
    required List<JournalEntry> transactions,
  }) {
    if (accounts.isEmpty) {
      emit(const GeneralLedgerState(status: BlocStatus.success));
      return;
    }

    Account targetAccount;
    if (state.selectedAccount != null &&
        accounts.any((a) => a.id == state.selectedAccount!.id)) {
      targetAccount = accounts.firstWhere(
        (a) => a.id == state.selectedAccount!.id,
      );
    } else {
      targetAccount = accounts.first;
    }

    selectAccount(account: targetAccount, transactions: transactions);
  }

  List<LedgerEntry> _computeLedgerEntries(
    Account account,
    List<JournalEntry> transactions,
  ) {
    double runningBalance = 0.0;
    final sortedTx = List<JournalEntry>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    final isNormalDebit = AccountTypes.isNormalDebit(account.type);
    final ledgerEntries = <LedgerEntry>[];

    for (final t in sortedTx) {
      if (t.isDraft) continue;
      for (final line in t.lines) {
        if (line.accountId == account.id) {
          final debit = line.debit;
          final credit = line.credit;

          if (isNormalDebit) {
            runningBalance += (debit - credit);
          } else {
            runningBalance += (credit - debit);
          }

          ledgerEntries.add(
            LedgerEntry(
              date: t.date,
              description: t.description,
              txId: t.id,
              debit: debit,
              credit: credit,
              balance: runningBalance,
            ),
          );
        }
      }
    }

    return ledgerEntries;
  }

  Future<ExportResult?> exportCsv(PrintConfig config) async {
    if (state.selectedAccount == null) return null;
    emit(state.copyWith(status: BlocStatus.loading));
    try {
      final res = await _exportService.exportGeneralLedgerToCsv(
        account: state.selectedAccount!,
        entries: state.filteredEntries,
        printConfig: config,
      );
      emit(
        state.copyWith(
          status: BlocStatus.success,
          lastExport: res,
          errorMessage: null,
        ),
      );
      return res;
    } catch (e) {
      emit(
        state.copyWith(
          status: BlocStatus.failure,
          errorMessage: 'Export failed: $e',
        ),
      );
      return null;
    }
  }

  FormattedPrintDocument? preparePrint(PrintConfig config) {
    if (state.selectedAccount == null) return null;
    final doc = _printService.generateGeneralLedgerPrintDocument(
      account: state.selectedAccount!,
      entries: state.filteredEntries,
      config: config,
    );
    emit(state.copyWith(lastPrintDoc: doc));
    return doc;
  }
}
