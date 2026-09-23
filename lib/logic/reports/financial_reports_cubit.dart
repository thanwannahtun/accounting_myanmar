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

  FinancialReportsCubit({
    ExportService? exportService,
    PrintService? printService,
  })  : _exportService = exportService ?? ExportService.instance,
        _printService = printService ?? PrintService.instance,
        super(const FinancialReportsState());

  void recompute({
    required List<Account> accounts,
    required List<JournalEntry> transactions,
  }) {
    emit(state.copyWith(status: BlocStatus.loading));
    try {
      // 1. Calculate balances per account
      final balances = <String, double>{};
      for (final acc in accounts) {
        balances[acc.id] = 0.0;
      }

      for (final t in transactions) {
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

      // Group accounts by type
      final groupedAccounts = <String, List<Account>>{};
      for (final acc in accounts) {
        groupedAccounts.putIfAbsent(acc.type, () => []).add(acc);
      }

      // 2. Compute Income Statement
      double totalRevenue = 0.0;
      double totalCogs = 0.0;
      double totalOpex = 0.0;

      final revenueLines = <ReportLineItem>[];
      final revenues = groupedAccounts[AccountTypes.revenue] ?? [];
      for (final acc in revenues) {
        final bal = balances[acc.id] ?? 0.0;
        final displayAmount = acc.code == '4100' ? -bal : bal;
        totalRevenue += bal;
        revenueLines.add(ReportLineItem(account: acc, amount: displayAmount));
      }

      final cogsLines = <ReportLineItem>[];
      final opexLines = <ReportLineItem>[];
      final expenses = groupedAccounts[AccountTypes.expense] ?? [];
      for (final acc in expenses) {
        final bal = balances[acc.id] ?? 0.0;
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

      // 3. Compute Balance Sheet
      double totalAssets = 0.0;
      double totalLiabilities = 0.0;
      double totalEquity = 0.0;

      final assetLines = <ReportLineItem>[];
      for (final acc in groupedAccounts[AccountTypes.asset] ?? []) {
        final bal = balances[acc.id] ?? 0.0;
        totalAssets += bal;
        assetLines.add(ReportLineItem(account: acc, amount: bal));
      }

      final liabilityLines = <ReportLineItem>[];
      for (final acc in groupedAccounts[AccountTypes.liability] ?? []) {
        final bal = balances[acc.id] ?? 0.0;
        totalLiabilities += bal;
        liabilityLines.add(ReportLineItem(account: acc, amount: bal));
      }

      final equityLines = <ReportLineItem>[];
      for (final acc in groupedAccounts[AccountTypes.equity] ?? []) {
        final bal = balances[acc.id] ?? 0.0;
        totalEquity += bal;
        equityLines.add(ReportLineItem(account: acc, amount: bal));
      }

      // Net Income for the period
      double netIncome = 0.0;
      for (final acc in accounts) {
        final bal = balances[acc.id] ?? 0.0;
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

      // 4. Compute Dashboard Metrics & Cash Flow
      final dashboardMetrics = DashboardMetrics(
        totalRevenue: totalRevenue,
        totalExpenses: totalCogs + totalOpex,
        netProfit: netProfit,
        totalAssets: totalAssets,
      );

      final cashFlowTxs = transactions
          .where((t) => t.lines.any((l) => l.accountId == 'a1000' || l.accountId.toLowerCase().contains('cash')))
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

  Future<ExportResult?> exportIncomeStatementCsv(PrintConfig config) async {
    if (state.incomeStatement == null) return null;
    emit(state.copyWith(status: BlocStatus.loading));
    try {
      final res = await _exportService.exportIncomeStatementToCsv(
        report: state.incomeStatement!,
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

  Future<ExportResult?> exportBalanceSheetCsv(PrintConfig config) async {
    if (state.balanceSheet == null) return null;
    emit(state.copyWith(status: BlocStatus.loading));
    try {
      final res = await _exportService.exportBalanceSheetToCsv(
        report: state.balanceSheet!,
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

  FormattedPrintDocument? prepareIncomeStatementPrint(PrintConfig config) {
    if (state.incomeStatement == null) return null;
    final doc = _printService.generateIncomeStatementPrintDocument(
      report: state.incomeStatement!,
      config: config,
    );
    emit(state.copyWith(lastPrintDoc: doc));
    return doc;
  }

  FormattedPrintDocument? prepareBalanceSheetPrint(PrintConfig config) {
    if (state.balanceSheet == null) return null;
    final doc = _printService.generateBalanceSheetPrintDocument(
      report: state.balanceSheet!,
      config: config,
    );
    emit(state.copyWith(lastPrintDoc: doc));
    return doc;
  }
}
