import 'package:flutter_bloc/flutter_bloc.dart';
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

  GeneralLedgerCubit({
    ExportService? exportService,
    PrintService? printService,
  })  : _exportService = exportService ?? ExportService.instance,
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
      emit(state.copyWith(
        status: BlocStatus.success,
        selectedAccount: account,
        entries: entries,
        endingBalance: endingBalance,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: 'Failed to compute ledger entries: $e',
      ));
    }
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
      targetAccount =
          accounts.firstWhere((a) => a.id == state.selectedAccount!.id);
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
        entries: state.entries,
        printConfig: config,
      );
      emit(state.copyWith(
        status: BlocStatus.success,
        lastExport: res,
        errorMessage: null,
      ));
      return res;
    } catch (e) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: 'Export failed: $e',
      ));
      return null;
    }
  }

  FormattedPrintDocument? preparePrint(PrintConfig config) {
    if (state.selectedAccount == null) return null;
    final doc = _printService.generateGeneralLedgerPrintDocument(
      account: state.selectedAccount!,
      entries: state.entries,
      config: config,
    );
    emit(state.copyWith(lastPrintDoc: doc));
    return doc;
  }
}
