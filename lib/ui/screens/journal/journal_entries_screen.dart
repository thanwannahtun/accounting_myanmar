import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/journal_entry.dart';
import '../../../data/models/journal_entry_line.dart';
import '../../../logic/account/account_cubit.dart';
import '../../../logic/journal/journal_entry_cubit.dart';
import '../../../logic/journal/journal_entry_state.dart';
import '../../../logic/ledger/general_ledger_cubit.dart';
import '../../../logic/reports/financial_reports_cubit.dart';
import 'add_journal_entry_dialog.dart';
import 'journal_entry_detail_dialog.dart';

class JournalEntriesScreen extends StatefulWidget {
  const JournalEntriesScreen({super.key});

  @override
  State<JournalEntriesScreen> createState() => _JournalEntriesScreenState();
}

class _JournalEntriesScreenState extends State<JournalEntriesScreen> {
  String _selectedFilter = 'all'; // 'all', 'posted', 'draft'

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
              String? remark,
              required List<JournalEntryLine> lines,
              bool isDraft = false,
            }) async {
              final journalCubit = context.read<JournalEntryCubit>();
              final accountCubit = context.read<AccountCubit>();
              final ledgerCubit = context.read<GeneralLedgerCubit>();
              final reportsCubit = context.read<FinancialReportsCubit>();

              await journalCubit.addJournalEntry(
                date: date,
                description: description,
                remark: remark,
                lines: lines,
                isDraft: isDraft,
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

  void _openEntryDetail(BuildContext context, JournalEntry tx) {
    final accounts = context.read<AccountCubit>().state.accounts;
    showDialog(
      context: context,
      builder: (dialogCtx) => JournalEntryDetailDialog(
        entry: tx,
        accounts: accounts,
        onReverse: tx.canReverse
            ? () => _confirmReverseEntry(context, tx)
            : null,
        onPost: tx.isDraft ? () => _confirmPostDraft(context, tx) : null,
        onDeleteDraft: tx.isDraft
            ? () => _confirmDeleteDraft(context, tx)
            : null,
      ),
    );
  }

  Future<void> _confirmPostDraft(BuildContext context, JournalEntry tx) async {
    final journalCubit = context.read<JournalEntryCubit>();
    final accountCubit = context.read<AccountCubit>();
    final ledgerCubit = context.read<GeneralLedgerCubit>();
    final reportsCubit = context.read<FinancialReportsCubit>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.check_circle_outline, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'မူကြမ်းအား အတည်ပြုသွင်းမည်လား? (Post Draft)',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'စာရင်းအမှတ်: #${tx.id.length > 8 ? tx.id.substring(0, 8) : tx.id}\n'
              'အကြောင်းအရာ: "${tx.description}"',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'ဤမူကြမ်းအား စာရင်းအတည်ပြု (Post) လိုက်ပါက General Ledger နှင့် ဘဏ္ဍာရေး အစီရင်ခံစာများထဲသို့ တိုက်ရိုက် ထည့်သွင်းသွားမည်ဖြစ်ပြီး၊ ထပ်မံဖျက်ပစ်ခွင့် မရှိတော့ဘဲ စံနှုန်းအတိုင်း Reverse Entry ဖြင့်သာ ပြင်ဆင်နိုင်တော့မည် ဖြစ်ပါသည်။\n\n'
              'စာရင်းအတည်ပြုရန် သေချာပါသလား?',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('မလုပ်ဆောင်ပါ (Cancel)'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.check_circle_outline, size: 16),
            label: const Text('အတည်ပြုမည် (Post)'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await journalCubit.postDraftEntry(tx);

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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'စာရင်းအတည်ပြုပြီးပါပြီ။ General Ledger သို့ ထည့်သွင်းပြီးဖြစ်ပါသည်။',
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    }
  }

  Future<void> _confirmReverseEntry(
    BuildContext context,
    JournalEntry tx,
  ) async {
    final journalCubit = context.read<JournalEntryCubit>();
    final accountCubit = context.read<AccountCubit>();
    final ledgerCubit = context.read<GeneralLedgerCubit>();
    final reportsCubit = context.read<FinancialReportsCubit>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.swap_horiz, color: AppColors.primaryGold),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'စာရင်းပြောင်းပြန်လှန်မည်လား? (Reverse Entry)',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'စာရင်းအမှတ်: #${tx.id.length > 8 ? tx.id.substring(0, 8) : tx.id}\n'
              'အကြောင်းအရာ: "${tx.description}"',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            const Text(
              'နိုင်ငံတကာ စာရင်းကိုင်စံနှုန်းများအရ အတည်ပြုပြီးသော စာရင်းအား တိုက်ရိုက်ဖျက်ပစ်ခြင်း မပြုဘဲ Debit နှင့် Credit နေရာလဲလှယ်ထားသော Counterpart Reversal စာရင်းသစ်တစ်ခု ဖန်တီး၍ မူလစာရင်းကို အလိုအလျောက် ပယ်ဖျက်ပေးမည်ဖြစ်ပါသည်။ (Preserve Audit Trail)\n\n'
              'ဤသို့ ပြောင်းပြန်လှန်ခြင်းကို ဆက်လက်လုပ်ဆောင်လိုပါသလား?',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('မလုပ်ဆောင်ပါ (Cancel)'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGold,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.swap_horiz, size: 16),
            label: const Text('ပြောင်းပြန်လှန်မည် (Reverse)'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await journalCubit.reverseJournalEntry(originalEntry: tx);

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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'စာရင်းပြောင်းပြန်လှန်မှု အောင်မြင်ပါသည်။ (Entry successfully reversed)',
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteDraft(
    BuildContext context,
    JournalEntry tx,
  ) async {
    final journalCubit = context.read<JournalEntryCubit>();
    final accountCubit = context.read<AccountCubit>();
    final ledgerCubit = context.read<GeneralLedgerCubit>();
    final reportsCubit = context.read<FinancialReportsCubit>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('မူကြမ်းဖျက်မည်လား? (Delete Draft)'),
        content: Text(
          'မူကြမ်း "${tx.description}" အား ဖျက်ပစ်ရန် သေချာပါသလား?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete Draft',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await journalCubit.deleteJournalEntry(tx.id);

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
    }
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
          final allEntries = state.entries;
          final accounts = context.watch<AccountCubit>().state.accounts;

          final postedCount = allEntries
              .where((e) => e.isPosted || e.isReversed || e.isReversal)
              .length;
          final draftCount = allEntries.where((e) => e.isDraft).length;

          final displayedEntries = allEntries.where((e) {
            if (_selectedFilter == 'posted') {
              return e.isPosted || e.isReversed || e.isReversal;
            }
            if (_selectedFilter == 'draft') {
              return e.isDraft;
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Segmented Lifecycle Filter Bar
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.sizeOf(context).width * 0.05,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        selected: _selectedFilter == 'all',
                        label: Text('အားလုံး (${allEntries.length})'),
                        onSelected: (_) =>
                            setState(() => _selectedFilter = 'all'),
                        selectedColor: AppColors.primaryGreen.withValues(
                          alpha: 0.18,
                        ),
                        checkmarkColor: AppColors.primaryGreen,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedFilter == 'all'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedFilter == 'all'
                              ? AppColors.primaryGreen
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _selectedFilter == 'posted',
                        label: Text('အတည်ပြုပြီး ($postedCount)'),
                        onSelected: (_) =>
                            setState(() => _selectedFilter = 'posted'),
                        selectedColor: AppColors.primaryGreen.withValues(
                          alpha: 0.18,
                        ),
                        checkmarkColor: AppColors.primaryGreen,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedFilter == 'posted'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedFilter == 'posted'
                              ? AppColors.primaryGreen
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _selectedFilter == 'draft',
                        label: Text('မူကြမ်းများ ($draftCount)'),
                        onSelected: (_) =>
                            setState(() => _selectedFilter = 'draft'),
                        selectedColor: Colors.blueGrey.withValues(alpha: 0.2),
                        checkmarkColor: Colors.blueGrey,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedFilter == 'draft'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedFilter == 'draft'
                              ? Colors.blueGrey
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Entry List
              Expanded(
                child: displayedEntries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 56,
                              color: isDark
                                  ? Colors.grey[700]
                                  : Colors.grey[400],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _selectedFilter == 'draft'
                                  ? 'မူကြမ်းစာရင်းများ မရှိပါ (No Drafts)'
                                  : (_selectedFilter == 'posted'
                                        ? 'အတည်ပြုပြီး စာရင်းများ မရှိပါ (No Posted Entries)'
                                        : 'စာရင်းသွင်းထားမှု မရှိသေးပါ (No Journal Entries)'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '+ New Entry ကိုနှိပ်၍ စာရင်း စတင်ရေးသွင်းပါ',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.sizeOf(context).width * 0.05,
                          vertical: 12,
                        ),
                        itemCount: displayedEntries.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final tx = displayedEntries[index];

                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => _openEntryDetail(context, tx),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 4,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: [
                                                  Text(
                                                    tx.date,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: isDark
                                                          ? Colors.grey[400]
                                                          : Colors.grey[600],
                                                    ),
                                                  ),
                                                  if (tx.isDraft)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 1.5,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blueGrey
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.blueGrey
                                                              .withValues(
                                                                alpha: 0.5,
                                                              ),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'DRAFT / မူကြမ်း',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors.blueGrey,
                                                        ),
                                                      ),
                                                    )
                                                  else if (tx.isReversed)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 1.5,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.amber
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.amber
                                                              .withValues(
                                                                alpha: 0.5,
                                                              ),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'REVERSED / ပြယ်ပြီး',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.amber,
                                                        ),
                                                      ),
                                                    )
                                                  else if (tx.isReversal)
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 1.5,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.indigo
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              4,
                                                            ),
                                                        border: Border.all(
                                                          color: Colors.indigo
                                                              .withValues(
                                                                alpha: 0.5,
                                                              ),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'REVERSAL',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors
                                                              .indigoAccent,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                tx.description,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  decoration: tx.isReversed
                                                      ? TextDecoration
                                                            .lineThrough
                                                      : null,
                                                  color: tx.isReversed
                                                      ? (isDark
                                                            ? Colors.grey[500]
                                                            : Colors.grey[600])
                                                      : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '#${tx.id.length > 8 ? tx.id.substring(0, 8) : tx.id}',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isDark
                                                      ? Colors.grey[400]
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            // Action Buttons:
                                            // 1. If Draft: Quick Post and Quick Delete Draft
                                            if (tx.isDraft) ...[
                                              IconButton(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding: const EdgeInsets.all(4),
                                                constraints:
                                                    const BoxConstraints(),
                                                icon: const Icon(
                                                  Icons.check_circle_outline,
                                                  size: 19,
                                                ),
                                                color: AppColors.primaryGreen,
                                                tooltip:
                                                    'Post draft (စာရင်းအတည်ပြုရန်)',
                                                onPressed: () =>
                                                    _confirmPostDraft(
                                                      context,
                                                      tx,
                                                    ),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding: const EdgeInsets.all(4),
                                                constraints:
                                                    const BoxConstraints(),
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                ),
                                                color: AppColors.creditRose,
                                                tooltip:
                                                    'Delete draft (မူကြမ်းဖျက်မည်)',
                                                onPressed: () =>
                                                    _confirmDeleteDraft(
                                                      context,
                                                      tx,
                                                    ),
                                              ),
                                              const SizedBox(width: 4),
                                            ],
                                            // 2. If Posted and can reverse: Reverse Action
                                            if (tx.canReverse) ...[
                                              IconButton(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding: const EdgeInsets.all(4),
                                                constraints:
                                                    const BoxConstraints(),
                                                icon: const Icon(
                                                  Icons.swap_horiz,
                                                  size: 19,
                                                ),
                                                color: AppColors.primaryGold,
                                                tooltip:
                                                    'Reverse entry (စာရင်းပြောင်းပြန်လှန်ရန်)',
                                                onPressed: () =>
                                                    _confirmReverseEntry(
                                                      context,
                                                      tx,
                                                    ),
                                              ),
                                              const SizedBox(width: 4),
                                            ],
                                            // Detail View Action
                                            IconButton(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding: const EdgeInsets.all(4),
                                              constraints:
                                                  const BoxConstraints(),
                                              icon: const Icon(
                                                Icons.visibility_outlined,
                                                size: 18,
                                              ),
                                              color: AppColors.primaryGreen,
                                              tooltip: 'View detail',
                                              onPressed: () =>
                                                  _openEntryDetail(context, tx),
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
                                          final accName = acc != null
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
                                                    accName,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    l.debit > 0
                                                        ? numberFormat.format(
                                                            l.debit,
                                                          )
                                                        : '-',
                                                    textAlign: TextAlign.right,
                                                    style: const TextStyle(
                                                      fontFamily: 'Courier',
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors
                                                          .primaryGreen,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    l.credit > 0
                                                        ? numberFormat.format(
                                                            l.credit,
                                                          )
                                                        : '-',
                                                    textAlign: TextAlign.right,
                                                    style: const TextStyle(
                                                      fontFamily: 'Courier',
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppColors.creditRose,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        if (tx.remark != null &&
                                            tx.remark!.trim().isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? Colors.white.withValues(
                                                      alpha: 0.04,
                                                    )
                                                  : Colors.black.withValues(
                                                      alpha: 0.03,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.notes,
                                                  size: 14,
                                                  color: isDark
                                                      ? Colors.grey[400]
                                                      : Colors.grey[600],
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    tx.remark!,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      color: isDark
                                                          ? Colors.grey[400]
                                                          : Colors.grey[600],
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
