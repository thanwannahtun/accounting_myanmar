import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/journal_entry_line.dart';
import '../../../logic/account/account_cubit.dart';
import '../../../logic/journal/journal_entry_cubit.dart';
import '../../../logic/journal/journal_entry_state.dart';
import '../../../logic/ledger/general_ledger_cubit.dart';
import '../../../logic/reports/financial_reports_cubit.dart';
import 'add_journal_entry_dialog.dart';

class JournalEntriesScreen extends StatelessWidget {
  const JournalEntriesScreen({super.key});

  void _openAddEntryDialog(BuildContext context) {
    final accounts = context.read<AccountCubit>().state.accounts;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AddJournalEntryDialog(
        accounts: accounts,
        onSave:
            ({
              required String date,
              required String description,
              required List<JournalEntryLine> lines,
            }) async {
              final journalCubit = context.read<JournalEntryCubit>();
              final accountCubit = context.read<AccountCubit>();
              final ledgerCubit = context.read<GeneralLedgerCubit>();
              final reportsCubit = context.read<FinancialReportsCubit>();

              await journalCubit.addJournalEntry(
                date: date,
                description: description,
                lines: lines,
              );

              final updatedAccounts = accountCubit.state.accounts;
              final updatedEntries = journalCubit.state.entries;

              ledgerCubit.refresh(
                accounts: updatedAccounts,
                transactions: updatedEntries,
              );
              reportsCubit.recompute(
                accounts: updatedAccounts,
                transactions: updatedEntries,
              );
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final numberFormat = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Entries (နေ့စဉ်စာရင်းသွင်းမှု)'),
        actions: [
          IconButton(
            tooltip: 'New Journal Entry',
            onPressed: () => _openAddEntryDialog(context),
            icon: const Icon(Icons.add_circle, color: AppColors.primaryGreen),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEntryDialog(context),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Entry',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<JournalEntryCubit, JournalEntryState>(
        builder: (context, state) {
          final entries = state.entries;
          final accounts = context.watch<AccountCubit>().state.accounts;

          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book,
                    size: 64,
                    color: isDark ? Colors.grey[700] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'စာရင်းသွင်းထားမှု မရှိသေးပါ (No Journal Entries)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+ New Entry ကိုနှိပ်၍ စာရင်း စတင်ရေးသွင်းပါ',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.only(
              left: MediaQuery.sizeOf(context).width * 0.05,
              right: MediaQuery.sizeOf(context).width * 0.05,
              top: 12,
              bottom: 80,
            ),
            itemCount: entries.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tx = entries[index];

              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Entry Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      color: isDark
                          ? const Color(0xFF14241B)
                          : const Color(0xFFF1F5F2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.date,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tx.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${tx.id}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                ),
                                color: Colors.grey,
                                tooltip: 'Delete entry',
                                onPressed: () async {
                                  final journalCubit = context
                                      .read<JournalEntryCubit>();
                                  final accountCubit = context
                                      .read<AccountCubit>();
                                  final ledgerCubit = context
                                      .read<GeneralLedgerCubit>();
                                  final reportsCubit = context
                                      .read<FinancialReportsCubit>();

                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text(
                                        'စာရင်းဖျက်မည်လား? (Delete Entry)',
                                      ),
                                      content: Text(
                                        '"${tx.description}" အား ဖျက်ပစ်ရန် သေချာပါသလား?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await journalCubit.deleteJournalEntry(
                                      tx.id,
                                    );

                                    final updatedAccounts =
                                        accountCubit.state.accounts;
                                    final updatedEntries =
                                        journalCubit.state.entries;

                                    ledgerCubit.refresh(
                                      accounts: updatedAccounts,
                                      transactions: updatedEntries,
                                    );
                                    reportsCubit.recompute(
                                      accounts: updatedAccounts,
                                      transactions: updatedEntries,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Lines Table
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                flex: 5,
                                child: Text(
                                  'Account',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Debit',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Credit',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 12),
                          ...tx.lines.map((l) {
                            final acc = accounts
                                .where((a) => a.id == l.accountId)
                                .firstOrNull;
                            final accLabel = acc != null
                                ? '${acc.code} - ${acc.name}'
                                : l.accountId;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Text(
                                      accLabel,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      l.debit > 0
                                          ? numberFormat.format(l.debit)
                                          : '-',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      l.credit > 0
                                          ? numberFormat.format(l.credit)
                                          : '-',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.creditRose,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
