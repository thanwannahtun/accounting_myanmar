import 'package:flutter_test/flutter_test.dart';
import 'package:accountingmyanmar/core/constants/account_types.dart';
import 'package:accountingmyanmar/core/constants/seed_data.dart';
import 'package:accountingmyanmar/data/models/account.dart';
import 'package:accountingmyanmar/data/models/financial_report.dart';
import 'package:accountingmyanmar/data/models/print_config.dart';
import 'package:accountingmyanmar/data/services/export/export_service.dart';

void main() {
  group('Accounting Domain & Calculations Tests', () {
    test('Seed Data integrity check', () {
      final accounts = SeedData.initialAccounts;
      final transactions = SeedData.initialTransactions;

      expect(accounts.length, 13);
      expect(transactions.length, 15);

      // Verify every transaction is balanced
      for (final tx in transactions) {
        expect(
          tx.isBalanced,
          isTrue,
          reason: 'Transaction ${tx.id} (${tx.description}) should be balanced',
        );
      }
    });

    test('Financial Statements & Balance Sheet equation test', () {
      final accounts = SeedData.initialAccounts;
      final transactions = SeedData.initialTransactions;

      final balances = <String, double>{};
      for (final acc in accounts) {
        balances[acc.id] = 0.0;
      }

      for (final t in transactions) {
        for (final line in t.lines) {
          final acc = accounts.firstWhere((a) => a.id == line.accountId);
          final amount = line.debit - line.credit;

          if (AccountTypes.isNormalDebit(acc.type)) {
            balances[acc.id] = (balances[acc.id] ?? 0.0) + amount;
          } else {
            balances[acc.id] = (balances[acc.id] ?? 0.0) - amount;
          }
        }
      }

      // Check specific accounts
      expect(balances['a1000'], isNotNull); // Cash / Bank
      expect(balances['a3000'], 100000000.0); // Owner Equity

      // Revenue and Expenses
      double totalRevenue = 0.0;
      double totalCogs = 0.0;
      double totalOpex = 0.0;

      for (final acc in accounts) {
        final bal = balances[acc.id] ?? 0.0;
        if (acc.type == AccountTypes.revenue) {
          totalRevenue += bal;
        } else if (acc.type == AccountTypes.expense) {
          if (acc.code.startsWith('5')) {
            totalCogs += bal;
          } else {
            totalOpex += bal;
          }
        }
      }

      final grossProfit = totalRevenue - totalCogs;
      final netProfit = grossProfit - totalOpex;

      // Assets
      double totalAssets = 0.0;
      for (final acc in accounts.where((a) => a.type == AccountTypes.asset)) {
        totalAssets += balances[acc.id] ?? 0.0;
      }

      // Liabilities
      double totalLiabilities = 0.0;
      for (final acc in accounts.where((a) => a.type == AccountTypes.liability)) {
        totalLiabilities += balances[acc.id] ?? 0.0;
      }

      // Equity
      double totalEquity = 0.0;
      for (final acc in accounts.where((a) => a.type == AccountTypes.equity)) {
        totalEquity += balances[acc.id] ?? 0.0;
      }

      final totalLiabilitiesAndEquity = totalLiabilities + totalEquity + netProfit;

      // Balance Sheet must balance perfectly: Assets == Liabilities + Equity + Net Profit
      expect(
        (totalAssets - totalLiabilitiesAndEquity).abs() < 0.01,
        isTrue,
        reason: 'Assets ($totalAssets) must equal Liabilities + Equity ($totalLiabilitiesAndEquity)',
      );
    });

    test('CSV Export content format test', () async {
      final account = const Account(
        id: 'a1000',
        code: '1000',
        name: 'Cash / Bank',
        type: AccountTypes.asset,
      );

      final entries = [
        const LedgerEntry(
          date: '2026-09-01',
          description: 'Initial Capital',
          txId: 't0',
          debit: 100000000,
          credit: 0,
          balance: 100000000,
        ),
      ];

      const config = PrintConfig(
        companyName: 'Test Company Ltd',
        slogan: 'Test Slogan',
        paperFormat: 'A4',
      );

      final exportResult = await ExportService.instance.exportGeneralLedgerToCsv(
        account: account,
        entries: entries,
        printConfig: config,
      );

      expect(exportResult.csvContent.contains('Test Company Ltd'), isTrue);
      expect(exportResult.csvContent.contains('1000 - Cash / Bank'), isTrue);
      expect(exportResult.csvContent.contains('Initial Capital'), isTrue);
      expect(exportResult.csvContent.contains('100000000.00'), isTrue);
    });
  });
}
