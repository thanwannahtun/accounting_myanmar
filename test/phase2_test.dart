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

    test('Journal entry remark and status defaults and serialization work correctly', () {
      final entry = JournalEntry(
        id: 'tx_rem_1',
        date: '2026-09-26',
        description: 'Inventory Purchase',
        remark: 'Invoice #INV-2026-009, vendor discount 5%',
        lines: [
          const JournalEntryLine(id: 'l1', journalEntryId: 'tx_rem_1', accountId: 'acc_inv', debit: 100000, credit: 0),
          const JournalEntryLine(id: 'l2', journalEntryId: 'tx_rem_1', accountId: 'acc_cash', debit: 0, credit: 100000),
        ],
      );

      expect(entry.status, 'active');
      expect(entry.remark, 'Invoice #INV-2026-009, vendor discount 5%');
      expect(entry.canReverse, isTrue);
      expect(entry.isReversed, isFalse);
      expect(entry.isReversal, isFalse);

      final map = entry.toMap();
      expect(map['remark'], 'Invoice #INV-2026-009, vendor discount 5%');
      expect(map['status'], 'active');
      expect(map['linked_transaction_id'], isNull);

      final restored = JournalEntry.fromMap(map, entry.lines);
      expect(restored.remark, entry.remark);
      expect(restored.status, 'active');
      expect(restored.canReverse, isTrue);
    });

    test('Standard Reversal Mechanism swaps Dr/Cr and links counterpart entries correctly', () {
      final original = JournalEntry(
        id: 'tx_orig',
        date: '2026-09-26',
        description: 'Payment to Supplier',
        remark: 'Wrong account used initially',
        lines: [
          const JournalEntryLine(id: 'l1', journalEntryId: 'tx_orig', accountId: 'acc_ap', debit: 75000, credit: 0),
          const JournalEntryLine(id: 'l2', journalEntryId: 'tx_orig', accountId: 'acc_bank', debit: 0, credit: 75000),
        ],
      );

      // Reversal logic simulation
      final reversalLines = original.lines.map((l) {
        return JournalEntryLine(
          id: 'rev_${l.id}',
          journalEntryId: 'tx_rev',
          accountId: l.accountId,
          debit: l.credit,
          credit: l.debit,
        );
      }).toList();

      final reversalEntry = JournalEntry(
        id: 'tx_rev',
        date: '2026-09-26',
        description: 'Reversal of Entry #tx_orig (Payment to Supplier)',
        remark: 'System auto-reversal',
        status: 'reversal',
        linkedTransactionId: original.id,
        lines: reversalLines,
      );

      final updatedOriginal = original.copyWith(
        status: 'reversed',
        linkedTransactionId: reversalEntry.id,
      );

      // Verify original status transition
      expect(updatedOriginal.status, 'reversed');
      expect(updatedOriginal.isReversed, isTrue);
      expect(updatedOriginal.canReverse, isFalse);
      expect(updatedOriginal.linkedTransactionId, 'tx_rev');

      // Verify counterpart reversal entry
      expect(reversalEntry.status, 'reversal');
      expect(reversalEntry.isReversal, isTrue);
      expect(reversalEntry.canReverse, isFalse);
      expect(reversalEntry.linkedTransactionId, 'tx_orig');

      // Verify Dr/Cr swapped
      expect(reversalLines[0].debit, 0);
      expect(reversalLines[0].credit, 75000);
      expect(reversalLines[1].debit, 75000);
      expect(reversalLines[1].credit, 0);

      // Verify ledger net impact is exactly zero
      final combinedLines = [...original.lines, ...reversalLines];
      final apDebit = combinedLines.where((l) => l.accountId == 'acc_ap').fold(0.0, (s, l) => s + l.debit);
      final apCredit = combinedLines.where((l) => l.accountId == 'acc_ap').fold(0.0, (s, l) => s + l.credit);
      expect(apDebit - apCredit, 0.0);

      final bankDebit = combinedLines.where((l) => l.accountId == 'acc_bank').fold(0.0, (s, l) => s + l.debit);
      final bankCredit = combinedLines.where((l) => l.accountId == 'acc_bank').fold(0.0, (s, l) => s + l.credit);
      expect(bankDebit - bankCredit, 0.0);
    });

    test('Draft vs Posted lifecycle: Drafts do NOT affect General Ledger & Reports', () {
      final postedTx = JournalEntry(
        id: 'tx_posted',
        date: '2026-09-26',
        description: 'Confirmed Cash Sale',
        status: 'posted',
        lines: [
          const JournalEntryLine(id: 'l1', journalEntryId: 'tx_posted', accountId: 'acc_cash', debit: 50000, credit: 0),
          const JournalEntryLine(id: 'l2', journalEntryId: 'tx_posted', accountId: 'acc_sales', debit: 0, credit: 50000),
        ],
      );

      final draftTx = JournalEntry(
        id: 'tx_draft',
        date: '2026-09-26',
        description: 'Provisional Quotation / Draft Entry',
        status: 'draft',
        lines: [
          const JournalEntryLine(id: 'l3', journalEntryId: 'tx_draft', accountId: 'acc_cash', debit: 999999, credit: 0),
          const JournalEntryLine(id: 'l4', journalEntryId: 'tx_draft', accountId: 'acc_sales', debit: 0, credit: 999999),
        ],
      );

      // Status check
      expect(postedTx.isPosted, isTrue);
      expect(postedTx.isDraft, isFalse);
      expect(postedTx.canReverse, isTrue);
      expect(postedTx.canDelete, isFalse);

      expect(draftTx.isDraft, isTrue);
      expect(draftTx.isPosted, isFalse);
      expect(draftTx.canReverse, isFalse);
      expect(draftTx.canDelete, isTrue);

      // Ledger calculation filtering test
      final allTransactions = [postedTx, draftTx];
      final activeLedgerTx = allTransactions.where((t) => !t.isDraft).toList();

      expect(activeLedgerTx.length, 1);
      expect(activeLedgerTx.first.id, 'tx_posted');

      // Cash balance must ONLY include posted entry (50,000), ignoring draft (999,999)
      double cashBalance = 0.0;
      for (final t in activeLedgerTx) {
        for (final l in t.lines.where((line) => line.accountId == 'acc_cash')) {
          cashBalance += (l.debit - l.credit);
        }
      }
      expect(cashBalance, 50000.0);

      // Transition test: Posting the draft
      final newlyPostedTx = draftTx.copyWith(status: 'posted');
      expect(newlyPostedTx.isPosted, isTrue);
      expect(newlyPostedTx.isDraft, isFalse);
      expect(newlyPostedTx.canReverse, isTrue);
      expect(newlyPostedTx.canDelete, isFalse);
    });
  });
}
