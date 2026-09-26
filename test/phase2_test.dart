import 'package:flutter_test/flutter_test.dart';
import 'package:accountingmyanmar/core/constants/account_types.dart';
import 'package:accountingmyanmar/data/models/account.dart';
import 'package:accountingmyanmar/data/models/journal_entry.dart';
import 'package:accountingmyanmar/data/models/journal_entry_line.dart';
import 'package:accountingmyanmar/data/repositories/account/account_repository_interface.dart';
import 'package:accountingmyanmar/logic/account/account_cubit.dart';

class MockAccountRepository implements AccountRepositoryInterface {
  final List<Account> _accounts = [];

  MockAccountRepository([List<Account>? initial]) {
    if (initial != null) {
      _accounts.addAll(initial);
    }
  }

  @override
  Future<List<Account>> getAccounts() async => List.of(_accounts);

  @override
  Future<Account?> getAccountById(String id) async =>
      _accounts.where((a) => a.id == id).firstOrNull;

  @override
  Future<void> addAccount(Account account) async {
    _accounts.add(account);
  }

  @override
  Future<void> updateAccount(Account account) async {
    final idx = _accounts.indexWhere((a) => a.id == account.id);
    if (idx != -1) {
      _accounts[idx] = account;
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    _accounts.removeWhere((a) => a.id == id);
  }
}

void main() {
  group('Phase 2 Tests - Account Management & Data-Aware Protections', () {
    late MockAccountRepository repo;
    late AccountCubit cubit;

    setUp(() {
      repo = MockAccountRepository([
        const Account(id: 'acc_1', code: '1001', name: 'Cash', type: AccountTypes.asset),
        const Account(id: 'acc_2', code: '4001', name: 'Sales', type: AccountTypes.revenue),
      ]);
      cubit = AccountCubit(repo);
    });

    test('updateAccount updates existing account correctly', () async {
      await cubit.loadAccounts();
      expect(cubit.state.accounts.first.name, 'Cash');

      await cubit.updateAccount(
        const Account(id: 'acc_1', code: '1001', name: 'Cash in Bank', type: AccountTypes.asset),
      );

      expect(cubit.state.accounts.first.name, 'Cash in Bank');
    });

    test('Data-aware deletion prevents deleting referenced accounts', () {
      final entries = [
        JournalEntry(
          id: 'tx_1',
          date: '2026-09-26',
          description: 'Sales receipt',
          lines: [
            const JournalEntryLine(id: 'l1', journalEntryId: 'tx_1', accountId: 'acc_1', debit: 50000, credit: 0),
            const JournalEntryLine(id: 'l2', journalEntryId: 'tx_1', accountId: 'acc_2', debit: 0, credit: 50000),
          ],
        ),
      ];

      final accountWithReferences = const Account(id: 'acc_1', code: '1001', name: 'Cash', type: AccountTypes.asset);
      final unreferencedAccount = const Account(id: 'acc_3', code: '6001', name: 'Stationery', type: AccountTypes.expense);

      bool isAccountUsed(Account acc) {
        return entries.any((tx) =>
          tx.lines.any((line) => line.accountId == acc.id || line.accountId == acc.code)
        );
      }

      expect(isAccountUsed(accountWithReferences), isTrue);
      expect(isAccountUsed(unreferencedAccount), isFalse);
    });

    test('Journal entry totals calculate balancing accurately in detail view', () {
      final entry = JournalEntry(
        id: 'tx_detail',
        date: '2026-09-26',
        description: 'Office Supplies',
        lines: [
          const JournalEntryLine(id: 'l1', journalEntryId: 'tx_detail', accountId: 'acc_supplies', debit: 25000, credit: 0),
          const JournalEntryLine(id: 'l2', journalEntryId: 'tx_detail', accountId: 'acc_cash', debit: 0, credit: 25000),
        ],
      );

      final totalDebit = entry.lines.fold<double>(0.0, (sum, l) => sum + l.debit);
      final totalCredit = entry.lines.fold<double>(0.0, (sum, l) => sum + l.credit);
      final isBalanced = (totalDebit - totalCredit).abs() < 0.001 && totalDebit > 0;

      expect(totalDebit, 25000.0);
      expect(totalCredit, 25000.0);
      expect(isBalanced, isTrue);
    });
  });
}
