import 'package:equatable/equatable.dart';
import '../../core/bloc_utils/bloc_status.dart';
import '../../data/models/financial_report.dart';
import '../../data/models/journal_entry.dart';
import '../../data/services/export/export_service.dart';
import '../../data/services/print/print_service.dart';

class FinancialReportsState extends Equatable {
  final BlocStatus status;
  final IncomeStatementReport? incomeStatement;
  final BalanceSheetReport? balanceSheet;
  final DashboardMetrics? dashboardMetrics;
  final List<JournalEntry> cashFlowTransactions;
  final ExportResult? lastExport;
  final FormattedPrintDocument? lastPrintDoc;
  final String? errorMessage;

  const FinancialReportsState({
    this.status = BlocStatus.initial,
    this.incomeStatement,
    this.balanceSheet,
    this.dashboardMetrics,
    this.cashFlowTransactions = const [],
    this.lastExport,
    this.lastPrintDoc,
    this.errorMessage,
  });

  FinancialReportsState copyWith({
    BlocStatus? status,
    IncomeStatementReport? incomeStatement,
    BalanceSheetReport? balanceSheet,
    DashboardMetrics? dashboardMetrics,
    List<JournalEntry>? cashFlowTransactions,
    ExportResult? lastExport,
    FormattedPrintDocument? lastPrintDoc,
    String? errorMessage,
  }) {
    return FinancialReportsState(
      status: status ?? this.status,
      incomeStatement: incomeStatement ?? this.incomeStatement,
      balanceSheet: balanceSheet ?? this.balanceSheet,
      dashboardMetrics: dashboardMetrics ?? this.dashboardMetrics,
      cashFlowTransactions: cashFlowTransactions ?? this.cashFlowTransactions,
      lastExport: lastExport ?? this.lastExport,
      lastPrintDoc: lastPrintDoc ?? this.lastPrintDoc,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    incomeStatement,
    balanceSheet,
    dashboardMetrics,
    cashFlowTransactions,
    lastExport,
    lastPrintDoc,
    errorMessage,
  ];
}
