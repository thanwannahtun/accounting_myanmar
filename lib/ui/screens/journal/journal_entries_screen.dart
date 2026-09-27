import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/journal_entry.dart';
import '../../../data/models/journal_entry_line.dart';
import '../../../logic/account/account_cubit.dart';
import '../../../logic/cash_flow/cash_flow_cubit.dart';
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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<JournalEntryCubit>().loadMoreEntries();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(
    BuildContext context,
    JournalEntryState state,
  ) async {
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2100);

    DateTimeRange? initialRange;
    if (state.startDate != null && state.endDate != null) {
      try {
        final start = DateFormat('yyyy-MM-dd').parse(state.startDate!);
        final end = DateFormat('yyyy-MM-dd').parse(state.endDate!);
        initialRange = DateTimeRange(start: start, end: end);
      } catch (_) {}
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: initialRange,
      helpText: 'ရက်စွဲအပိုင်းအခြား ရွေးချယ်ပါ (Select Date Range)',
      saveText: 'ရွေးမည် (Apply)',
      cancelText: 'မလုပ်ပါ (Cancel)',
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primaryGreen,
                    onPrimary: Colors.white,
                    surface: AppColors.darkCard,
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primaryGreen,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final startStr = DateFormat('yyyy-MM-dd').format(picked.start);
      final endStr = DateFormat('yyyy-MM-dd').format(picked.end);
      if (context.mounted) {
        context.read<JournalEntryCubit>().setDateRange(startStr, endStr);
      }
    }
  }

  void _openAddEntryDialog(BuildContext context) {
    final accounts = context.read<AccountCubit>().state.accounts;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AddJournalEntryDialog(
        accounts: accounts,
        onSave:
            ({
              String? id,
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
              final cashFlowCubit = context.read<CashFlowCubit>();

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
              cashFlowCubit.updateData(
                accounts: updatedAccounts,
                transactions: updatedEntries,
              );
            },
      ),
    );
  }

  void _openEditEntryDialog(BuildContext context, JournalEntry tx) {
    if (!tx.isDraft) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'အတည်ပြုပြီးသော စာရင်းများကို တိုက်ရိုက်ပြင်ခွင့် မရှိပါ။ (Only drafts can be edited)',
          ),
          backgroundColor: AppColors.creditRose,
        ),
      );
      return;
    }

    final accounts = context.read<AccountCubit>().state.accounts;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AddJournalEntryDialog(
        accounts: accounts,
        initialEntry: tx,
        onSave:
            ({
              String? id,
              required String date,
              required String description,
              String? remark,
              required List<JournalEntryLine> lines,
              bool isDraft = true,
            }) async {
              final journalCubit = context.read<JournalEntryCubit>();
              final accountCubit = context.read<AccountCubit>();
              final ledgerCubit = context.read<GeneralLedgerCubit>();
              final reportsCubit = context.read<FinancialReportsCubit>();
              final cashFlowCubit = context.read<CashFlowCubit>();

              await journalCubit.updateJournalEntry(
                id: id ?? tx.id,
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
              cashFlowCubit.updateData(
                accounts: updatedAccounts,
                transactions: updatedEntries,
              );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isDraft
                          ? 'မူကြမ်း အချက်အလက် ပြင်ဆင်ပြီးပါပြီ။'
                          : 'မူကြမ်းအား အတည်ပြု စာရင်းသွင်းပြီးပါပြီ။',
                    ),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
              }
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
        onEditDraft: tx.isDraft
            ? () => _openEditEntryDialog(context, tx)
            : null,
      ),
    );
  }

  Future<void> _confirmPostDraft(BuildContext context, JournalEntry tx) async {
    final journalCubit = context.read<JournalEntryCubit>();
    final accountCubit = context.read<AccountCubit>();
    final ledgerCubit = context.read<GeneralLedgerCubit>();
    final reportsCubit = context.read<FinancialReportsCubit>();
    final cashFlowCubit = context.read<CashFlowCubit>();

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
      cashFlowCubit.updateData(
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
    final cashFlowCubit = context.read<CashFlowCubit>();

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
      cashFlowCubit.updateData(
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
    final cashFlowCubit = context.read<CashFlowCubit>();

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
      cashFlowCubit.updateData(
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
        automaticallyImplyLeading: false,
        title: const Text('Journal Entries (နေ့စဉ်စာရင်းသွင်းမှု)'),
        actions: [
          IconButton(
            tooltip: _isSearchExpanded ? 'Close Search' : 'Search Entries',
            icon: Icon(
              _isSearchExpanded ? Icons.close : Icons.search,
              color: _isSearchExpanded ? AppColors.creditRose : null,
            ),
            onPressed: () {
              setState(() {
                _isSearchExpanded = !_isSearchExpanded;
                if (!_isSearchExpanded) {
                  _searchController.clear();
                  context.read<JournalEntryCubit>().setSearchQuery('');
                }
              });
            },
          ),
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
          final displayedEntries = state.visibleEntries;
          final hasDateFilter =
              state.startDate != null || state.endDate != null;

          return Column(
            children: [
              // Search Input Row (expandable)
              if (_isSearchExpanded)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.sizeOf(context).width * 0.05,
                    vertical: 8,
                  ),
                  color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'အကြောင်းအရာ၊ မှတ်ချက်၊ အမှတ် ရှာဖွေပါ...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                context
                                    .read<JournalEntryCubit>()
                                    .setSearchQuery('');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (val) {
                      context.read<JournalEntryCubit>().setSearchQuery(val);
                    },
                  ),
                ),

              // Filter Bar (Lifecycle + Date Range + Sort Order)
              Container(
                width: double.infinity,
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
                        selected: state.lifecycleFilter == 'all',
                        label: Text('အားလုံး (${allEntries.length})'),
                        onSelected: (_) => context
                            .read<JournalEntryCubit>()
                            .setLifecycleFilter('all'),
                        selectedColor: AppColors.primaryGreen.withValues(
                          alpha: 0.18,
                        ),
                        checkmarkColor: AppColors.primaryGreen,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: state.lifecycleFilter == 'all'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: state.lifecycleFilter == 'all'
                              ? AppColors.primaryGreen
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: state.lifecycleFilter == 'posted',
                        label: Text('အတည်ပြုပြီး (${state.postedCount})'),
                        onSelected: (_) => context
                            .read<JournalEntryCubit>()
                            .setLifecycleFilter('posted'),
                        selectedColor: AppColors.primaryGreen.withValues(
                          alpha: 0.18,
                        ),
                        checkmarkColor: AppColors.primaryGreen,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: state.lifecycleFilter == 'posted'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: state.lifecycleFilter == 'posted'
                              ? AppColors.primaryGreen
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: state.lifecycleFilter == 'draft',
                        label: Text('မူကြမ်းများ (${state.draftCount})'),
                        onSelected: (_) => context
                            .read<JournalEntryCubit>()
                            .setLifecycleFilter('draft'),
                        selectedColor: Colors.blueGrey.withValues(alpha: 0.2),
                        checkmarkColor: Colors.blueGrey,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: state.lifecycleFilter == 'draft'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: state.lifecycleFilter == 'draft'
                              ? Colors.blueGrey
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 22,
                        width: 1,
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                      const SizedBox(width: 12),

                      // Date Range Chip
                      ActionChip(
                        avatar: Icon(
                          Icons.date_range,
                          size: 15,
                          color: hasDateFilter
                              ? AppColors.primaryGreen
                              : Colors.grey,
                        ),
                        label: Text(
                          hasDateFilter
                              ? '${state.startDate} ~ ${state.endDate}'
                              : 'ရက်စွဲ (Date Range)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: hasDateFilter
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: hasDateFilter
                                ? AppColors.primaryGreen
                                : null,
                          ),
                        ),
                        backgroundColor: hasDateFilter
                            ? AppColors.primaryGreen.withValues(alpha: 0.12)
                            : null,
                        side: hasDateFilter
                            ? const BorderSide(color: AppColors.primaryGreen)
                            : null,
                        onPressed: () => _pickDateRange(context, state),
                      ),
                      if (hasDateFilter) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: 'Clear Date Filter',
                          icon: const Icon(
                            Icons.cancel,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onPressed: () => context
                              .read<JournalEntryCubit>()
                              .clearDateRange(),
                        ),
                      ],
                      const SizedBox(width: 12),
                      Container(
                        height: 22,
                        width: 1,
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                      const SizedBox(width: 12),

                      // Sort Toggle Button
                      ActionChip(
                        avatar: Icon(
                          state.isAscending
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 15,
                          color: AppColors.primaryGold,
                        ),
                        label: Text(
                          state.isAscending
                              ? 'အဟောင်းမှ အသစ်'
                              : 'အသစ်မှ အဟောင်း',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () => context
                            .read<JournalEntryCubit>()
                            .setSortOrder(!state.isAscending),
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
                              state.lifecycleFilter == 'draft'
                                  ? 'မူကြမ်းစာရင်းများ မရှိပါ (No Drafts)'
                                  : (state.lifecycleFilter == 'posted'
                                        ? 'အတည်ပြုပြီး စာရင်းများ မရှိပါ (No Posted Entries)'
                                        : 'စာရင်းသွင်းထားမှု မရှိသေးပါ (No Journal Entries)'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              hasDateFilter || state.searchQuery.isNotEmpty
                                  ? 'ရှာဖွေမှု / ရက်စွဲ စံနှုန်းများနှင့် ကိုက်ညီသော စာရင်း မရှိပါ'
                                  : '+ New Entry ကိုနှိပ်၍ စာရင်း စတင်ရေးသွင်းပါ',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            if (hasDateFilter ||
                                state.searchQuery.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.filter_alt_off,
                                  size: 16,
                                ),
                                label: const Text(
                                  'Filter များ ရှင်းလင်းမည် (Reset Filters)',
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  context
                                      .read<JournalEntryCubit>()
                                      .clearDateRange();
                                  context
                                      .read<JournalEntryCubit>()
                                      .setSearchQuery('');
                                  context
                                      .read<JournalEntryCubit>()
                                      .setLifecycleFilter('all');
                                },
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.sizeOf(context).width * 0.05,
                          vertical: 12,
                        ),
                        itemCount: displayedEntries.length + 1,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index == displayedEntries.length) {
                            return _buildPaginationFooter(
                              context,
                              state,
                              isDark,
                            );
                          }
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
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                constraints:
                                                    const BoxConstraints(),
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 18,
                                                ),
                                                color: AppColors.primaryGold,
                                                tooltip: 'Edit draft (မူကြမ်းပြင်ဆင်ရန်)',
                                                onPressed: () =>
                                                    _openEditEntryDialog(
                                                      context,
                                                      tx,
                                                    ),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                constraints:
                                                    const BoxConstraints(),
                                                icon: const Icon(
                                                  Icons.check_circle_outline,
                                                  size: 19,
                                                ),
                                                color: AppColors.primaryGreen,
                                                tooltip: 'Post draft (စာရင်းအတည်ပြုရန်)',
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
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                constraints:
                                                    const BoxConstraints(),
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                ),
                                                color: AppColors.creditRose,
                                                tooltip: 'Delete draft (မူကြမ်းဖျက်မည်)',
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
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                constraints:
                                                    const BoxConstraints(),
                                                icon: const Icon(
                                                  Icons.swap_horiz,
                                                  size: 19,
                                                ),
                                                color: AppColors.primaryGold,
                                                tooltip: 'Reverse entry (စာရင်းပြောင်းပြန်လှန်ရန်)',
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

  Widget _buildPaginationFooter(
    BuildContext context,
    JournalEntryState state,
    bool isDark,
  ) {
    if (state.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'နောက်ထပ် စာရင်းများ ဖတ်ယူနေပါသည်... (Loading more...)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Center(
        child: Text(
          '✓ စုစုပေါင်း (${state.totalFilteredCount}) ခု အားလုံး ဖော်ပြပြီးပါပြီ',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[500] : Colors.grey[400],
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
