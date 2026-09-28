import 'package:equatable/equatable.dart';
import '../../core/bloc_utils/bloc_status.dart';
import '../../data/models/account.dart';
import '../../data/models/financial_report.dart';
import '../../data/services/export/export_service.dart';
import '../../data/services/print/print_service.dart';

class GeneralLedgerState extends Equatable {
  final BlocStatus status;
  final Account? selectedAccount;
  final List<LedgerEntry> entries;
  final double endingBalance;
  final ExportResult? lastExport;
  final FormattedPrintDocument? lastPrintDoc;
  final String? errorMessage;
  final String dateFilterMode; // 'all', 'this_month', 'this_year', 'custom'
  final String? startDate; // 'yyyy-MM-dd'
  final String? endDate; // 'yyyy-MM-dd'
  final String searchQuery;
  final int pageLimit;

  const GeneralLedgerState({
    this.status = BlocStatus.initial,
    this.selectedAccount,
    this.entries = const [],
    this.endingBalance = 0.0,
    this.lastExport,
    this.lastPrintDoc,
    this.errorMessage,
    this.dateFilterMode = 'all',
    this.startDate,
    this.endDate,
    this.searchQuery = '',
    this.pageLimit = 20,
  });

  /// All entries that match active date filters and search query.
  /// Used for calculating totals, ending balance, exports, and prints (independent of pagination).
  List<LedgerEntry> get filteredEntries {
    final query = searchQuery.trim().toLowerCase();
    return entries.where((e) {
      // 1. Date range filter
      if (startDate != null && e.date.compareTo(startDate!) < 0) {
        return false;
      }
      if (endDate != null && e.date.compareTo(endDate!) > 0) {
        return false;
      }

      // 2. Search query filter
      if (query.isNotEmpty) {
        final descMatches = e.description.toLowerCase().contains(query);
        final dateMatches = e.date.contains(query);
        final debitMatches = e.debit > 0 && e.debit.toString().contains(query);
        final creditMatches =
            e.credit > 0 && e.credit.toString().contains(query);
        if (!descMatches && !dateMatches && !debitMatches && !creditMatches) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Paginated slice of filtered entries for UI display
  List<LedgerEntry> get visibleEntries {
    final filtered = filteredEntries;
    if (pageLimit >= filtered.length) return filtered;
    return filtered.take(pageLimit).toList();
  }

  bool get hasMore => visibleEntries.length < filteredEntries.length;
  int get totalFilteredCount => filteredEntries.length;

  /// Total debit amount in filtered range (exact, not limited to 20!)
  double get filteredDebitTotal =>
      filteredEntries.fold(0.0, (sum, e) => sum + e.debit);

  /// Total credit amount in filtered range (exact, not limited to 20!)
  double get filteredCreditTotal =>
      filteredEntries.fold(0.0, (sum, e) => sum + e.credit);

  /// Exact ending balance for the filtered range
  double get filteredEndingBalance {
    if (filteredEntries.isNotEmpty) {
      return filteredEntries.last.balance;
    }
    if (entries.isEmpty) return 0.0;
    if (endDate != null) {
      final prior = entries.where((e) => e.date.compareTo(endDate!) <= 0);
      return prior.isNotEmpty ? prior.last.balance : 0.0;
    }
    return endingBalance;
  }

  /// Opening balance before startDate (if a date filter is applied)
  double get openingBalance {
    if (startDate == null || entries.isEmpty) return 0.0;
    final prior = entries.where((e) => e.date.compareTo(startDate!) < 0);
    return prior.isNotEmpty ? prior.last.balance : 0.0;
  }

  GeneralLedgerState copyWith({
    BlocStatus? status,
    Account? selectedAccount,
    List<LedgerEntry>? entries,
    double? endingBalance,
    ExportResult? lastExport,
    FormattedPrintDocument? lastPrintDoc,
    String? errorMessage,
    String? dateFilterMode,
    String? startDate,
    String? endDate,
    bool clearDates = false,
    String? searchQuery,
    int? pageLimit,
  }) {
    return GeneralLedgerState(
      status: status ?? this.status,
      selectedAccount: selectedAccount ?? this.selectedAccount,
      entries: entries ?? this.entries,
      endingBalance: endingBalance ?? this.endingBalance,
      lastExport: lastExport ?? this.lastExport,
      lastPrintDoc: lastPrintDoc ?? this.lastPrintDoc,
      errorMessage: errorMessage ?? this.errorMessage,
      dateFilterMode: dateFilterMode ?? this.dateFilterMode,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      searchQuery: searchQuery ?? this.searchQuery,
      pageLimit: pageLimit ?? this.pageLimit,
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedAccount,
        entries,
        endingBalance,
        lastExport,
        lastPrintDoc,
        errorMessage,
        dateFilterMode,
        startDate,
        endDate,
        searchQuery,
        pageLimit,
      ];
}
