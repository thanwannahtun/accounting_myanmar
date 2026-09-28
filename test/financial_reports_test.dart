import 'package:flutter_test/flutter_test.dart';
import 'package:accountingmyanmar/core/constants/seed_data.dart';
import 'package:accountingmyanmar/data/models/journal_entry.dart';
import 'package:accountingmyanmar/data/models/journal_entry_line.dart';
import 'package:accountingmyanmar/data/models/print_config.dart';
import 'package:accountingmyanmar/logic/reports/financial_reports_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FinancialReportsCubit Date Filtering Tests', () {
    late FinancialReportsCubit cubit;

    setUp(() {
      cubit = FinancialReportsCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('recompute calculates all-time P&L and Balance Sheet correctly', () {
      final accounts = SeedData.initialAccounts;
      final transactions = SeedData.initialTransactions;

      cubit.recompute(accounts: accounts, transactions: transactions);

      expect(cubit.state.incomeStatement, isNotNull);
      expect(cubit.state.balanceSheet, isNotNull);
      expect(cubit.state.balanceSheet!.isBalanced, isTrue);
      expect(cubit.state.pnlFilterMode, 'all');
      expect(cubit.state.pnlStartDate, isNull);
      expect(cubit.state.pnlEndDate, isNull);
      expect(cubit.state.balanceSheetAsOfDate, isNull);
    });

    test('P&L custom date filtering includes only transactions in range', () {
      final accounts = SeedData.initialAccounts;
      // tx1 in 2026-01-10: Revenue 500,000 MMK (Cash Dr 500000, Revenue Cr 500000)
      final tx1 = JournalEntry(
        id: 'tx_jan',
        date: '2026-01-10',
        description: 'January Sale',
        lines: const [
          JournalEntryLine(
            id: 'l1',
            journalEntryId: 'tx_jan',
            accountId: 'a1000',
            debit: 500000,
            credit: 0,
          ),
          JournalEntryLine(
            id: 'l2',
            journalEntryId: 'tx_jan',
            accountId: 'a4000',
            debit: 0,
            credit: 500000,
          ),
        ],
      );
      // tx2 in 2026-02-15: Revenue 800,000 MMK (Cash Dr 800000, Revenue Cr 800000)
      final tx2 = JournalEntry(
        id: 'tx_feb',
        date: '2026-02-15',
        description: 'February Sale',
        lines: const [
          JournalEntryLine(
            id: 'l3',
            journalEntryId: 'tx_feb',
            accountId: 'a1000',
            debit: 800000,
            credit: 0,
          ),
          JournalEntryLine(
            id: 'l4',
            journalEntryId: 'tx_feb',
            accountId: 'a4000',
            debit: 0,
            credit: 800000,
          ),
        ],
      );
      // tx3 in 2026-02-20: Expense 200,000 MMK (Expense Dr 200000, Cash Cr 200000)
      final tx3 = JournalEntry(
        id: 'tx_feb_exp',
        date: '2026-02-20',
        description: 'February Salaries',
        lines: const [
          JournalEntryLine(
            id: 'l5',
            journalEntryId: 'tx_feb_exp',
            accountId: 'a6001',
            debit: 200000,
            credit: 0,
          ),
          JournalEntryLine(
            id: 'l6',
            journalEntryId: 'tx_feb_exp',
            accountId: 'a1000',
            debit: 0,
            credit: 200000,
          ),
        ],
      );

      cubit.recompute(
        accounts: accounts,
        transactions: [tx1, tx2, tx3],
      );

      // 1. All-time: Revenue = 1,300,000, Expense = 200,000, Net Profit = 1,100,000
      expect(cubit.state.incomeStatement!.totalRevenue, 1300000.0);
      expect(cubit.state.incomeStatement!.totalOperatingExpenses, 200000.0);
      expect(cubit.state.incomeStatement!.netProfit, 1100000.0);

      // 2. Filter to January only:
      cubit.setPnlCustomDateRange('2026-01-01', '2026-01-31');
      expect(cubit.state.pnlFilterMode, 'custom');
      expect(cubit.state.pnlStartDate, '2026-01-01');
      expect(cubit.state.pnlEndDate, '2026-01-31');
      expect(cubit.state.incomeStatement!.totalRevenue, 500000.0);
      expect(cubit.state.incomeStatement!.totalOperatingExpenses, 0.0);
      expect(cubit.state.incomeStatement!.netProfit, 500000.0);

      // 3. Filter to February only:
      cubit.setPnlCustomDateRange('2026-02-01', '2026-02-28');
      expect(cubit.state.incomeStatement!.totalRevenue, 800000.0);
      expect(cubit.state.incomeStatement!.totalOperatingExpenses, 200000.0);
      expect(cubit.state.incomeStatement!.netProfit, 600000.0);

      // 4. Reset / Clear filter
      cubit.clearPnlFilter();
      expect(cubit.state.pnlFilterMode, 'all');
      expect(cubit.state.incomeStatement!.totalRevenue, 1300000.0);
    });

    test('Balance Sheet as-of cut-off date calculates cumulative balances and stays balanced', () {
      final accounts = SeedData.initialAccounts;
      // Jan: Initial Capital (10,000,000)
      final tx0 = JournalEntry(
        id: 'tx_cap',
        date: '2026-01-01',
        description: 'Initial Capital',
        lines: const [
          JournalEntryLine(
            id: 'l0_1',
            journalEntryId: 'tx_cap',
            accountId: 'a1000',
            debit: 10000000,
            credit: 0,
          ),
          JournalEntryLine(
            id: 'l0_2',
            journalEntryId: 'tx_cap',
            accountId: 'a3000',
            debit: 0,
            credit: 10000000,
          ),
        ],
      );
      // Jan: Sale (1,000,000)
      final tx1 = JournalEntry(
        id: 'tx_jan_sale',
        date: '2026-01-15',
        description: 'Jan Sale',
        lines: const [
          JournalEntryLine(
            id: 'l1_1',
            journalEntryId: 'tx_jan_sale',
            accountId: 'a1000',
            debit: 1000000,
            credit: 0,
          ),
          JournalEntryLine(
            id: 'l1_2',
            journalEntryId: 'tx_jan_sale',
            accountId: 'a4000',
            debit: 0,
            credit: 1000000,
          ),
        ],
      );
      // Feb: Inventory Purchase (3,000,000)
      final tx2 = JournalEntry(
        id: 'tx_feb_asset',
        date: '2026-02-10',
        description: 'Inventory purchase',
        lines: const [
          JournalEntryLine(
            id: 'l2_1',
            journalEntryId: 'tx_feb_asset',
            accountId: 'a1300',
            debit: 3000000,
            credit: 0,
          ),
          JournalEntryLine(
            id: 'l2_2',
            journalEntryId: 'tx_feb_asset',
            accountId: 'a1000',
            debit: 0,
            credit: 3000000,
          ),
        ],
      );
      // March: Loan (Accounts Payable / Borrowing 2,000,000)
      final tx3 = JournalEntry(
        id: 'tx_mar_loan',
        date: '2026-03-01',
        description: 'Trade Payable',
        lines: const [
          JournalEntryLine(
            id: 'l3_1',
            journalEntryId: 'tx_mar_loan',
            accountId: 'a1000',
            debit: 2000000,
            credit: 0,
          ),
          JournalEntryLine(
            id: 'l3_2',
            journalEntryId: 'tx_mar_loan',
            accountId: 'a2000',
            debit: 0,
            credit: 2000000,
          ),
        ],
      );

      cubit.recompute(
        accounts: accounts,
        transactions: [tx0, tx1, tx2, tx3],
      );

      // As of Jan 31: Should only include tx0 and tx1
      cubit.setBalanceSheetAsOfDate('2026-01-31');
      expect(cubit.state.balanceSheetAsOfDate, '2026-01-31');
      expect(cubit.state.balanceSheet!.isBalanced, isTrue);
      expect(cubit.state.balanceSheet!.totalAssets, 11000000.0); // 10M cash + 1M cash
      expect(cubit.state.balanceSheet!.totalEquity, 10000000.0); // 10M capital
      expect(cubit.state.balanceSheet!.currentPeriodNetIncome, 1000000.0); // 1M profit
      expect(cubit.state.balanceSheet!.totalLiabilities, 0.0);

      // As of Feb 28: Should include tx0, tx1, tx2 (Inventory purchase)
      cubit.setBalanceSheetAsOfDate('2026-02-28');
      expect(cubit.state.balanceSheet!.isBalanced, isTrue);
      // Total assets: Cash (8M) + Inventory (3M) = 11M
      expect(cubit.state.balanceSheet!.totalAssets, 11000000.0);
      expect(cubit.state.balanceSheet!.totalLiabilities, 0.0);

      // As of March 31: Should include tx3 (Payable 2M)
      cubit.setBalanceSheetAsOfDate('2026-03-31');
      expect(cubit.state.balanceSheet!.isBalanced, isTrue);
      // Total assets: 11M + 2M loan = 13M
      expect(cubit.state.balanceSheet!.totalAssets, 13000000.0);
      expect(cubit.state.balanceSheet!.totalLiabilities, 2000000.0);

      // Reset
      cubit.clearBalanceSheetDate();
      expect(cubit.state.balanceSheetAsOfDate, isNull);
      expect(cubit.state.balanceSheet!.isBalanced, isTrue);
    });

    test('prepareIncomeStatementPrint and prepareBalanceSheetPrint contain labels', () {
      final accounts = SeedData.initialAccounts;
      final transactions = SeedData.initialTransactions;

      cubit.recompute(accounts: accounts, transactions: transactions);
      cubit.setPnlCustomDateRange('2026-01-01', '2026-03-31');
      cubit.setBalanceSheetAsOfDate('2026-03-31');

      const config = PrintConfig(
        companyName: 'Myanmar Accounting Pro',
        slogan: 'Best Accounting',
        paperFormat: 'A4',
      );

      final pnlDoc = cubit.prepareIncomeStatementPrint(config);
      expect(pnlDoc, isNotNull);
      expect(pnlDoc!.content.contains('Period: 2026-01-01 ~ 2026-03-31'), isTrue);

      final bsDoc = cubit.prepareBalanceSheetPrint(config);
      expect(bsDoc, isNotNull);
      expect(bsDoc!.content.contains('As of Date: 2026-03-31'), isTrue);
    });
  });
}
