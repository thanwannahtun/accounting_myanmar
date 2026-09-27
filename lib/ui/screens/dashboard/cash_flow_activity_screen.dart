import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/journal_entry.dart';
import '../../../logic/account/account_cubit.dart';
import '../../../logic/cash_flow/cash_flow_cubit.dart';
import '../../../logic/cash_flow/cash_flow_state.dart';
import '../../../logic/journal/journal_entry_cubit.dart';
import '../../../logic/ledger/general_ledger_cubit.dart';
import '../../../logic/reports/financial_reports_cubit.dart';
import '../../widgets/currency_formatter.dart';
import '../journal/journal_entry_detail_dialog.dart';

class CashFlowActivityScreen extends StatefulWidget {
  const CashFlowActivityScreen({super.key});

  @override
  State<CashFlowActivityScreen> createState() => _CashFlowActivityScreenState();
}

class _CashFlowActivityScreenState extends State<CashFlowActivityScreen> {
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
      context.read<CashFlowCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(BuildContext context, CashFlowState state) async {
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
        context.read<CashFlowCubit>().setDateRange(startStr, endStr);
      }
    }
  }

  void _openDetailDialog(BuildContext context, JournalEntry tx) {
    final accounts = context.read<AccountCubit>().state.accounts;
    showDialog(
      context: context,
      builder: (ctx) => JournalEntryDetailDialog(
        entry: tx,
        accounts: accounts,
        onReverse: tx.canReverse ? () => _confirmReverse(context, tx) : null,
      ),
    );
  }

  Future<void> _confirmReverse(BuildContext context, JournalEntry tx) async {
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
        content: Text(
          'စာရင်းအမှတ် #${tx.id} အား ပြောင်းပြန်လှန်ရန် သေချာပါသလား?',
          style: const TextStyle(fontSize: 13),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ငွေသားလှုပ်ရှားမှု စာရင်း (Cash Flow Activity)'),
        actions: [
          IconButton(
            tooltip: _isSearchExpanded ? 'Close Search' : 'Search Activities',
            icon: Icon(
              _isSearchExpanded ? Icons.close : Icons.search,
              color: _isSearchExpanded ? AppColors.creditRose : null,
            ),
            onPressed: () {
              setState(() {
                _isSearchExpanded = !_isSearchExpanded;
                if (!_isSearchExpanded) {
                  _searchController.clear();
                  context.read<CashFlowCubit>().setSearchQuery('');
                }
              });
            },
          ),
        ],
      ),
      body: BlocBuilder<CashFlowCubit, CashFlowState>(
        builder: (context, state) {
          final visibleItems = state.visibleActivities;

          return Column(
            children: [
              // Search Input Row (expandable)
              if (_isSearchExpanded)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.sizeOf(context).width * 0.05,
                    vertical: 16,
                  ),
                  color: isDark ? AppColors.darkCard : AppColors.lightSurface,
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'ဖော်ပြချက်၊ အကောင့်၊ ပမာဏ ရှာဖွေပါ...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                context.read<CashFlowCubit>().setSearchQuery(
                                  '',
                                );
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
                      context.read<CashFlowCubit>().setSearchQuery(val);
                    },
                  ),
                ),

              // KPI Summary Banner
              _buildKpiSummary(context, state, isDark),

              // Filter & Sort Toolbar
              _buildFilterBar(context, state, isDark),

              // Activity List with Lazy Loading
              Expanded(
                child: visibleItems.isEmpty
                    ? _buildEmptyState(isDark, state)
                    : ListView.separated(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.sizeOf(context).width * 0.05,
                          vertical: 16,
                        ),
                        itemCount: visibleItems.length + 1,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == visibleItems.length) {
                            return _buildPaginationFooter(
                              context,
                              state,
                              isDark,
                            );
                          }

                          final item = visibleItems[index];
                          return _buildActivityCard(context, item, isDark);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiSummary(
    BuildContext context,
    CashFlowState state,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width * 0.05,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightCard,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;

          if (isNarrow) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        label: 'စုစုပေါင်း ငွေဝင် (Inflow)',
                        amount: state.totalInflow,
                        color: AppColors.primaryGreen,
                        icon: Icons.arrow_downward,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricTile(
                        label: 'စုစုပေါင်း ငွေထွက် (Outflow)',
                        amount: state.totalOutflow,
                        color: AppColors.creditRose,
                        icon: Icons.arrow_upward,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildMetricTile(
                  label: 'အသားတင် ငွေသားစီးဆင်းမှု (Net Cash Flow)',
                  amount: state.netCashFlow,
                  color: state.netCashFlow >= 0
                      ? AppColors.primaryGreen
                      : AppColors.creditRose,
                  icon: Icons.account_balance_wallet_outlined,
                  isDark: isDark,
                  isFullWidth: true,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'စုစုပေါင်း ငွေဝင် (Inflow)',
                  amount: state.totalInflow,
                  color: AppColors.primaryGreen,
                  icon: Icons.arrow_downward,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'စုစုပေါင်း ငွေထွက် (Outflow)',
                  amount: state.totalOutflow,
                  color: AppColors.creditRose,
                  icon: Icons.arrow_upward,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  label: 'အသားတင် ငွေသားစီးဆင်းမှု (Net)',
                  amount: state.netCashFlow,
                  color: state.netCashFlow >= 0
                      ? AppColors.primaryGreen
                      : AppColors.creditRose,
                  icon: Icons.account_balance_wallet_outlined,
                  isDark: isDark,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
    required bool isDark,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.format(amount),
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    CashFlowState state,
    bool isDark,
  ) {
    final hasDateFilter = state.startDate != null || state.endDate != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width * 0.05,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Flow Type: All
            FilterChip(
              selected: state.flowTypeFilter == 'all',
              label: Text('အားလုံး (${state.allActivities.length})'),
              onSelected: (_) =>
                  context.read<CashFlowCubit>().setFlowTypeFilter('all'),
              selectedColor: AppColors.primaryGreen.withValues(alpha: 0.18),
              checkmarkColor: AppColors.primaryGreen,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: state.flowTypeFilter == 'all'
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: state.flowTypeFilter == 'all'
                    ? AppColors.primaryGreen
                    : null,
              ),
            ),
            const SizedBox(width: 8),

            // Flow Type: Inflow
            FilterChip(
              selected: state.flowTypeFilter == 'inflow',
              avatar: const Icon(
                Icons.arrow_downward,
                size: 14,
                color: AppColors.primaryGreen,
              ),
              label: const Text('ငွေဝင် (+)'),
              onSelected: (_) =>
                  context.read<CashFlowCubit>().setFlowTypeFilter('inflow'),
              selectedColor: AppColors.primaryGreen.withValues(alpha: 0.18),
              checkmarkColor: AppColors.primaryGreen,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: state.flowTypeFilter == 'inflow'
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: state.flowTypeFilter == 'inflow'
                    ? AppColors.primaryGreen
                    : null,
              ),
            ),
            const SizedBox(width: 8),

            // Flow Type: Outflow
            FilterChip(
              selected: state.flowTypeFilter == 'outflow',
              avatar: const Icon(
                Icons.arrow_upward,
                size: 14,
                color: AppColors.creditRose,
              ),
              label: const Text('ငွေထွက် (-)'),
              onSelected: (_) =>
                  context.read<CashFlowCubit>().setFlowTypeFilter('outflow'),
              selectedColor: AppColors.creditRose.withValues(alpha: 0.18),
              checkmarkColor: AppColors.creditRose,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: state.flowTypeFilter == 'outflow'
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: state.flowTypeFilter == 'outflow'
                    ? AppColors.creditRose
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 22,
              width: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            const SizedBox(width: 12),

            // Date Range Chip
            ActionChip(
              avatar: Icon(
                Icons.date_range,
                size: 15,
                color: hasDateFilter ? AppColors.primaryGreen : Colors.grey,
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
                  color: hasDateFilter ? AppColors.primaryGreen : null,
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
                icon: const Icon(Icons.cancel, size: 16, color: Colors.grey),
                onPressed: () => context.read<CashFlowCubit>().clearDateRange(),
              ),
            ],
            const SizedBox(width: 12),
            Container(
              height: 22,
              width: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            const SizedBox(width: 12),

            // Sort Toggle Button
            ActionChip(
              avatar: Icon(
                state.isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 15,
                color: AppColors.primaryGold,
              ),
              label: Text(
                state.isAscending ? 'အဟောင်းမှ အသစ်' : 'အသစ်မှ အဟောင်း',
                style: const TextStyle(fontSize: 12),
              ),
              onPressed: () => context.read<CashFlowCubit>().setSortOrder(
                !state.isAscending,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    CashFlowActivityItem item,
    bool isDark,
  ) {
    final isPositive = item.isInflow;
    final absAmount = item.netAmount.abs();

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openDetailDialog(context, item.entry),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Flow Icon Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    (isPositive ? AppColors.primaryGreen : AppColors.creditRose)
                        .withValues(alpha: 0.12),
                child: Icon(
                  isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isPositive
                      ? AppColors.primaryGreen
                      : AppColors.creditRose,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Title, Date, & Account info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          item.entry.date,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (isPositive
                                        ? AppColors.primaryGreen
                                        : AppColors.creditRose)
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isPositive
                                ? 'INFLOW / ငွေဝင်'
                                : 'OUTFLOW / ငွေထွက်',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isPositive
                                  ? AppColors.primaryGreen
                                  : AppColors.creditRose,
                            ),
                          ),
                        ),
                        if (item.entry.isReversed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'REVERSED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.entry.description,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.cashAccountName,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Amount & Detail Icon
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPositive ? '+' : '-'}${CurrencyFormatter.format(absAmount)}',
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isPositive
                          ? AppColors.primaryGreen
                          : AppColors.creditRose,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#${item.entry.id.length > 8 ? item.entry.id.substring(0, 8) : item.entry.id}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(
    BuildContext context,
    CashFlowState state,
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
                'နောက်ထပ် လှုပ်ရှားမှုများ ဖတ်ယူနေပါသည်... (Loading more...)',
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

  Widget _buildEmptyState(bool isDark, CashFlowState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 56,
            color: isDark ? Colors.grey[700] : Colors.grey[400],
          ),
          const SizedBox(height: 14),
          const Text(
            'ငွေသားလှုပ်ရှားမှု စာရင်း မရှိပါ (No Cash Activities)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            state.startDate != null || state.searchQuery.isNotEmpty
                ? 'ရှာဖွေမှု/ရက်စွဲ စံနှုန်းများနှင့် ကိုက်ညီသော စာရင်း မရှိပါ'
                : 'ငွေသား (သို့) ဘဏ်အကောင့် ပါဝင်သော စာရင်းသွင်းမှုများ မရှိသေးပါ',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          if (state.startDate != null || state.searchQuery.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.filter_alt_off, size: 16),
              label: const Text('Filter များ ရှင်းလင်းမည် (Reset Filters)'),
              onPressed: () {
                _searchController.clear();
                context.read<CashFlowCubit>().clearDateRange();
                context.read<CashFlowCubit>().setSearchQuery('');
                context.read<CashFlowCubit>().setFlowTypeFilter('all');
              },
            ),
          ],
        ],
      ),
    );
  }
}
