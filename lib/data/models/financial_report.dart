import 'package:equatable/equatable.dart';
import 'account.dart';

class LedgerEntry extends Equatable {
  final String date;
  final String description;
  final String txId;
  final double debit;
  final double credit;
  final double balance;

  const LedgerEntry({
    required this.date,
    required this.description,
    required this.txId,
    required this.debit,
    required this.credit,
    required this.balance,
  });

  @override
  List<Object?> get props => [date, description, txId, debit, credit, balance];
}

class ReportLineItem extends Equatable {
  final Account account;
  final double amount;

  const ReportLineItem({
    required this.account,
    required this.amount,
  });

  @override
  List<Object?> get props => [account, amount];
}

class IncomeStatementReport extends Equatable {
  final List<ReportLineItem> revenues;
  final double totalRevenue;
  final List<ReportLineItem> costOfGoodsSold;
  final double totalCogs;
  final double grossProfit;
  final List<ReportLineItem> operatingExpenses;
  final double totalOperatingExpenses;
  final double netProfit;

  const IncomeStatementReport({
    required this.revenues,
    required this.totalRevenue,
    required this.costOfGoodsSold,
    required this.totalCogs,
    required this.grossProfit,
    required this.operatingExpenses,
    required this.totalOperatingExpenses,
    required this.netProfit,
  });

  @override
  List<Object?> get props => [
    revenues,
    totalRevenue,
    costOfGoodsSold,
    totalCogs,
    grossProfit,
    operatingExpenses,
    totalOperatingExpenses,
    netProfit,
  ];
}

class BalanceSheetReport extends Equatable {
  final List<ReportLineItem> assets;
  final double totalAssets;
  final List<ReportLineItem> liabilities;
  final double totalLiabilities;
  final List<ReportLineItem> equities;
  final double totalEquity;
  final double currentPeriodNetIncome;
  final double totalLiabilitiesAndEquity;
  final bool isBalanced;

  const BalanceSheetReport({
    required this.assets,
    required this.totalAssets,
    required this.liabilities,
    required this.totalLiabilities,
    required this.equities,
    required this.totalEquity,
    required this.currentPeriodNetIncome,
    required this.totalLiabilitiesAndEquity,
    required this.isBalanced,
  });

  @override
  List<Object?> get props => [
    assets,
    totalAssets,
    liabilities,
    totalLiabilities,
    equities,
    totalEquity,
    currentPeriodNetIncome,
    totalLiabilitiesAndEquity,
    isBalanced,
  ];
}

class DashboardMetrics extends Equatable {
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final double totalAssets;

  const DashboardMetrics({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.totalAssets,
  });

  @override
  List<Object?> get props => [
    totalRevenue,
    totalExpenses,
    netProfit,
    totalAssets,
  ];
}
