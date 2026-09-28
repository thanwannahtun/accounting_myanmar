import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc_utils/bloc_status.dart';
import '../../core/constants/account_types.dart';
import '../../data/models/account.dart';
import '../../data/models/financial_report.dart';
import '../../data/models/journal_entry.dart';
import '../../data/models/print_config.dart';
import '../../data/services/export/export_service.dart';
import '../../data/services/print/print_service.dart';
import 'financial_reports_state.dart';

class FinancialReportsCubit extends Cubit<FinancialReportsState> {
  final ExportService _exportService;
  final PrintService _printService;

  List<Account> _accounts = [];
  List<JournalEntry> _transactions = [];

  FinancialReportsCubit({
    ExportService? exportService,
    PrintService? printService,
  })  : _exportService = exportService ?? ExportService.instance,
        _printService = printService ?? PrintService.instance,
        super(const FinancialReportsState());

  List<Account> get cachedAccounts => _accounts;
  List<JournalEntry> get cachedTransactions => _transactions;

  void recompute({
    List<Account>? accounts,
    List<JournalEntry>? transactions,
  }) {
    if (accounts != null) _accounts = accounts;
    if (transactions != null) _transactions = transactions;
    _recalculate();
  }

  void setPnlFilterMode(String mode) {
    if (mode == 'this_month') {
      final now = DateTime.now();
      final start = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
      final lastDay = DateTime(now.year, now.month + 1, 0).day;
      final end =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}';
      emit(state.copyWith(
        pnlFilterMode: 'this_month',
        pnlStartDate: start,
        pnlEndDate: end,
      ));
    } else if (mode == 'this_year') {
      final now = DateTime.now();
      final start = '${now.year}-01-01';
      final end = '${now.year}-12-31';
      emit(state.copyWith(
        pnlFilterMode: 'this_year',
        pnlStartDate: start,
        pnlEndDate: end,
      ));
    } else {
      emit(state.copyWith(
        pnlFilterMode: 'all',
        clearPnlDates: true,
      ));
    }
    _recalculate();
  }

  void setPnlCustomDateRange(String start, String end) {
    emit(state.copyWith(
      pnlFilterMode: 'custom',
      pnlStartDate: start,
      pnlEndDate: end,
    ));
    _recalculate();
  }

  void clearPnlFilter() {
    emit(state.copyWith(
      pnlFilterMode: 'all',
      clearPnlDates: true,
    ));
    _recalculate();
  }

  void setBalanceSheetAsOfDate(String? asOfDate) {
    if (asOfDate == null || asOfDate.isEmpty) {
      emit(state.copyWith(clearBalanceSheetAsOfDate: true));
    } else {
      emit(state.copyWith(balanceSheetAsOfDate: asOfDate));
    }
    _recalculate();
  }

  void clearBalanceSheetDate() {
    emit(state.copyWith(clearBalanceSheetAsOfDate: true));
    _recalculate();
  }

  Map<String, double> _calculateAccountBalances({
    required List<Account> accounts,
    required List<JournalEntry> transactions,
    String? startDate,
    String? endDate,
  }) {
    final balances = <String, double>{};
    for (final acc in accounts) {
      balances[acc.id] = 0.0;
    }

    for (final t in transactions) {
      if (t.isDraft) continue;
      final txDate = t.date.length >= 10 ? t.date.substring(0, 10) : t.date;
      if (startDate != null && txDate.compareTo(startDate) < 0) continue;
      if (endDate != null && txDate.compareTo(endDate) > 0) continue;

      for (final line in t.lines) {
        final acc = accounts.where((a) => a.id == line.accountId).firstOrNull;
        if (acc == null) continue;

        final amount = line.debit - line.credit;
        if (AccountTypes.isNormalDebit(acc.type)) {
          balances[acc.id] = (balances[acc.id] ?? 0.0) + amount;
        } else {
          balances[acc.id] = (balances[acc.id] ?? 0.0) - amount;
        }
      }
    }
    return balances;
  }

  void _recalculate() {
    emit(state.copyWith(status: BlocStatus.loading));
    try {
      final accounts = _accounts;
      final transactions = _transactions;

      // Group accounts by type
      final groupedAccounts = <String, List<Account>>{};
      for (final acc in accounts) {
        groupedAccounts.putIfAbsent(acc.type, () => []).add(acc);
      }

      // 1. Calculate Balances for Income Statement (Period-Filtered)
      final pnlBalances = _calculateAccountBalances(
        accounts: accounts,
        transactions: transactions,
        startDate: state.pnlStartDate,
        endDate: state.pnlEndDate,
      );

      // Compute Income Statement
      double totalRevenue = 0.0;
      double totalCogs = 0.0;
      double totalOpex = 0.0;

      final revenueLines = <ReportLineItem>[];
      final revenues = groupedAccounts[AccountTypes.revenue] ?? [];
      for (final acc in revenues) {
        final bal = pnlBalances[acc.id] ?? 0.0;
        final displayAmount = acc.code == '4100' ? -bal : bal;
        totalRevenue += bal;
        revenueLines.add(ReportLineItem(account: acc, amount: displayAmount));
      }

      final cogsLines = <ReportLineItem>[];
      final opexLines = <ReportLineItem>[];
      final expenses = groupedAccounts[AccountTypes.expense] ?? [];
      for (final acc in expenses) {
        final bal = pnlBalances[acc.id] ?? 0.0;
        if (acc.code.startsWith('5')) {
          totalCogs += bal;
          cogsLines.add(ReportLineItem(account: acc, amount: bal));
        } else {
          totalOpex += bal;
          opexLines.add(ReportLineItem(account: acc, amount: bal));
        }
      }

      final grossProfit = totalRevenue - totalCogs;
      final netProfit = grossProfit - totalOpex;

      final incomeStatement = IncomeStatementReport(
        revenues: revenueLines,
        totalRevenue: totalRevenue,
        costOfGoodsSold: cogsLines,
        totalCogs: totalCogs,
        grossProfit: grossProfit,
        operatingExpenses: opexLines,
        totalOperatingExpenses: totalOpex,
        netProfit: netProfit,
      );

      // 2. Calculate Balances for Balance Sheet (Cumulative up to As-Of Date)
      final bsBalances = _calculateAccountBalances(
        accounts: accounts,
        transactions: transactions,
        startDate: null,
        endDate: state.balanceSheetAsOfDate,
      );

      double totalAssets = 0.0;
      double totalLiabilities = 0.0;
      double totalEquity = 0.0;

      final assetLines = <ReportLineItem>[];
      for (final acc in groupedAccounts[AccountTypes.asset] ?? []) {
        final bal = bsBalances[acc.id] ?? 0.0;
        totalAssets += bal;
        assetLines.add(ReportLineItem(account: acc, amount: bal));
      }

      final liabilityLines = <ReportLineItem>[];
      for (final acc in groupedAccounts[AccountTypes.liability] ?? []) {
        final bal = bsBalances[acc.id] ?? 0.0;
        totalLiabilities += bal;
        liabilityLines.add(ReportLineItem(account: acc, amount: bal));
      }

      final equityLines = <ReportLineItem>[];
      for (final acc in groupedAccounts[AccountTypes.equity] ?? []) {
        final bal = bsBalances[acc.id] ?? 0.0;
        totalEquity += bal;
        equityLines.add(ReportLineItem(account: acc, amount: bal));
      }

      // Net Income up to As-Of Date
      double netIncome = 0.0;
      for (final acc in accounts) {
        final bal = bsBalances[acc.id] ?? 0.0;
        if (acc.type == AccountTypes.revenue) netIncome += bal;
        if (acc.type == AccountTypes.expense) netIncome -= bal;
      }

      final totalLiabilitiesAndEquity = totalLiabilities + totalEquity + netIncome;
      final isBalanced = (totalAssets - totalLiabilitiesAndEquity).abs() < 0.01;

      final balanceSheet = BalanceSheetReport(
        assets: assetLines,
        totalAssets: totalAssets,
        liabilities: liabilityLines,
        totalLiabilities: totalLiabilities,
        equities: equityLines,
        totalEquity: totalEquity,
        currentPeriodNetIncome: netIncome,
        totalLiabilitiesAndEquity: totalLiabilitiesAndEquity,
        isBalanced: isBalanced,
      );

      // 3. Compute All-Time Dashboard Metrics & Cash Flow
      final allTimeBalances = _calculateAccountBalances(
        accounts: accounts,
        transactions: transactions,
      );

      double allTimeRevenue = 0.0;
      double allTimeExpenses = 0.0;
      double allTimeAssets = 0.0;
      for (final acc in accounts) {
        final bal = allTimeBalances[acc.id] ?? 0.0;
        if (acc.type == AccountTypes.revenue) allTimeRevenue += bal;
        if (acc.type == AccountTypes.expense) allTimeExpenses += bal;
        if (acc.type == AccountTypes.asset) allTimeAssets += bal;
      }

      final dashboardMetrics = DashboardMetrics(
        totalRevenue: allTimeRevenue,
        totalExpenses: allTimeExpenses,
        netProfit: allTimeRevenue - allTimeExpenses,
        totalAssets: allTimeAssets,
      );

      final cashFlowTxs = transactions
          .where((t) =>
              !t.isDraft &&
              t.lines.any((l) =>
                  l.accountId == 'a1000' ||
                  l.accountId.toLowerCase().contains('cash')))
          .toList();

      emit(state.copyWith(
        status: BlocStatus.success,
        incomeStatement: incomeStatement,
        balanceSheet: balanceSheet,
        dashboardMetrics: dashboardMetrics,
        cashFlowTransactions: cashFlowTxs,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: 'Failed to compute financial statements: $e',
      ));
    }
  }

  String _getPnlPeriodLabel() {
    if (state.pnlFilterMode == 'this_month') {
      return 'This Month (${state.pnlStartDate} ~ ${state.pnlEndDate})';
    } else if (state.pnlFilterMode == 'this_year') {
      return 'This Year (${state.pnlStartDate} ~ ${state.pnlEndDate})';
    } else if (state.pnlStartDate != null || state.pnlEndDate != null) {
      return '${state.pnlStartDate ?? ""} ~ ${state.pnlEndDate ?? ""}';
    }
    return 'All Time';
  }

  String _getBalanceSheetAsOfLabel() {
    if (state.balanceSheetAsOfDate != null) {
      return state.balanceSheetAsOfDate!;
    }
    return 'All Time (Cumulative)';
  }

  Future<ExportResult?> exportIncomeStatementCsv(PrintConfig config) async {
    if (state.incomeStatement == null) return null;
    emit(state.copyWith(status: BlocStatus.loading));
    try {
      final res = await _exportService.exportIncomeStatementToCsv(
        report: state.incomeStatement!,
        printConfig: config,
        periodLabel: _getPnlPeriodLabel(),
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

  Future<ExportResult?> exportBalanceSheetCsv(PrintConfig config) async {
    if (state.balanceSheet == null) return null;
    emit(state.copyWith(status: BlocStatus.loading));
    try {
      final res = await _exportService.exportBalanceSheetToCsv(
        report: state.balanceSheet!,
        printConfig: config,
        asOfLabel: _getBalanceSheetAsOfLabel(),
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

  FormattedPrintDocument? prepareIncomeStatementPrint(PrintConfig config) {
    if (state.incomeStatement == null) return null;
    final doc = _printService.generateIncomeStatementPrintDocument(
      report: state.incomeStatement!,
      config: config,
      periodLabel: _getPnlPeriodLabel(),
    );
    emit(state.copyWith(lastPrintDoc: doc));
    return doc;
  }

  FormattedPrintDocument? prepareBalanceSheetPrint(PrintConfig config) {
    if (state.balanceSheet == null) return null;
    final doc = _printService.generateBalanceSheetPrintDocument(
      report: state.balanceSheet!,
      config: config,
      asOfLabel: _getBalanceSheetAsOfLabel(),
    );
    emit(state.copyWith(lastPrintDoc: doc));
    return doc;
  }
}
