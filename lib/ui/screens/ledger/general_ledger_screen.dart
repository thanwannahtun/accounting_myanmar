import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../logic/account/account_cubit.dart';
import '../../../logic/journal/journal_entry_cubit.dart';
import '../../../logic/ledger/general_ledger_cubit.dart';
import '../../../logic/ledger/general_ledger_state.dart';
import '../../../logic/settings/settings_cubit.dart';
import '../../widgets/account_type_badge.dart';
import '../../widgets/currency_formatter.dart';
import '../../widgets/export_dialog.dart';
import '../../widgets/print_preview_dialog.dart';

class GeneralLedgerScreen extends StatefulWidget {
  const GeneralLedgerScreen({super.key});

  @override
  State<GeneralLedgerScreen> createState() => _GeneralLedgerScreenState();
}

class _GeneralLedgerScreenState extends State<GeneralLedgerScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _mobileTableView = false;
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<GeneralLedgerCubit>().loadMoreEntries();
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
    GeneralLedgerState state,
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
        context.read<GeneralLedgerCubit>().setCustomDateRange(startStr, endStr);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final numberFormat = NumberFormat('#,##0.00', 'en_US');

    final accounts = context.watch<AccountCubit>().state.accounts;
    final transactions = context.watch<JournalEntryCubit>().state.entries;

    return BlocConsumer<GeneralLedgerCubit, GeneralLedgerState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final selectedAccount =
            state.selectedAccount ??
            (accounts.isNotEmpty ? accounts.first : null);
        final ledgerEntries = state.visibleEntries;
        final totalCount = state.totalFilteredCount;
        final endingBalance = state.filteredEndingBalance;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('General Ledger (အထွေထွေ လယ်ဂျာ)'),
            actions: [
              // Search Toggle Button
              IconButton(
                tooltip: _isSearchExpanded ? 'Close Search' : 'Search Ledger',
                icon: Icon(
                  _isSearchExpanded ? Icons.close : Icons.search,
                  color: _isSearchExpanded ? AppColors.creditRose : null,
                ),
                onPressed: () {
                  setState(() {
                    _isSearchExpanded = !_isSearchExpanded;
                    if (!_isSearchExpanded) {
                      _searchController.clear();
                      context.read<GeneralLedgerCubit>().setSearchQuery('');
                    }
                  });
                },
              ),
              // Export CSV Button
              IconButton(
                tooltip: 'Export CSV',
                icon: const Icon(
                  Icons.file_download_outlined,
                  color: AppColors.primaryGreen,
                ),
                onPressed: selectedAccount == null
                    ? null
                    : () async {
                        final printConfig = context
                            .read<SettingsCubit>()
                            .state
                            .printConfig;
                        final res = await context
                            .read<GeneralLedgerCubit>()
                            .exportCsv(printConfig);
                        if (res != null && context.mounted) {
                          showDialog(
                            context: context,
                            builder: (ctx) => ExportDialog(result: res),
                          );
                        }
                      },
              ),
              // Print Preview Button
              IconButton(
                tooltip: 'Print Ledger',
                icon: const Icon(
                  Icons.print_outlined,
                  color: AppColors.primaryGreen,
                ),
                onPressed: selectedAccount == null
                    ? null
                    : () {
                        final printConfig = context
                            .read<SettingsCubit>()
                            .state
                            .printConfig;
                        final defaultPrinter = context
                            .read<SettingsCubit>()
                            .state
                            .defaultPrinter;
                        final doc = context
                            .read<GeneralLedgerCubit>()
                            .preparePrint(printConfig);
                        if (doc != null && context.mounted) {
                          showDialog(
                            context: context,
                            builder: (ctx) => PrintPreviewDialog(
                              document: doc,
                              defaultPrinter: defaultPrinter,
                            ),
                          );
                        }
                      },
              ),
            ],
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width * 0.05,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Expandable Search Bar
                if (_isSearchExpanded)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'ဖော်ပြချက်၊ ရက်စွဲ၊ ပမာဏ ရှာဖွေပါ...',
                        hintStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  context
                                      .read<GeneralLedgerCubit>()
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
                        context.read<GeneralLedgerCubit>().setSearchQuery(val);
                      },
                    ),
                  ),

                // Top Account Selector Bar
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: selectedAccount?.id,
                        decoration: const InputDecoration(
                          labelText:
                              'Select Account (စာရင်းခေါင်းစဉ် ရွေးချယ်ပါ)',
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                        items: accounts.map((acc) {
                          return DropdownMenuItem<String>(
                            value: acc.id,
                            child: Text(
                              '${acc.code} - ${acc.name} (${acc.type})',
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            final picked = accounts.firstWhere(
                              (a) => a.id == val,
                            );
                            context.read<GeneralLedgerCubit>().selectAccount(
                              account: picked,
                              transactions: transactions,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Filter Toolbar (All, This Month, This Year, Custom Date Range)
                _buildFilterBar(context, state, isDark),

                const SizedBox(height: 12),

                // Responsive Account Summary Card
                if (selectedAccount != null)
                  _buildAccountSummaryCard(
                    context,
                    state,
                    selectedAccount,
                    endingBalance,
                    numberFormat,
                    isDark,
                  ),

                const SizedBox(height: 16),

                // Responsive Transaction History Card
                _buildTransactionHistoryCard(
                  context,
                  state,
                  ledgerEntries,
                  totalCount,
                  numberFormat,
                  isDark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    GeneralLedgerState state,
    bool isDark,
  ) {
    final hasDateFilter = state.startDate != null || state.endDate != null;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All FilterChip
          FilterChip(
            selected: state.dateFilterMode == 'all',
            label: Text('အားလုံး (${state.entries.length})'),
            onSelected: (_) {
              context.read<GeneralLedgerCubit>().setDateFilterMode('all');
            },
            selectedColor: AppColors.primaryGreen.withValues(alpha: 0.18),
            checkmarkColor: AppColors.primaryGreen,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: state.dateFilterMode == 'all'
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: state.dateFilterMode == 'all'
                  ? AppColors.primaryGreen
                  : null,
            ),
          ),
          const SizedBox(width: 8),

          // This Month FilterChip
          FilterChip(
            selected: state.dateFilterMode == 'this_month',
            avatar: const Icon(
              Icons.calendar_view_month,
              size: 14,
              color: AppColors.primaryGreen,
            ),
            label: const Text('ယခုလ (This Month)'),
            onSelected: (_) {
              context.read<GeneralLedgerCubit>().setDateFilterMode(
                'this_month',
              );
            },
            selectedColor: AppColors.primaryGreen.withValues(alpha: 0.18),
            checkmarkColor: AppColors.primaryGreen,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: state.dateFilterMode == 'this_month'
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: state.dateFilterMode == 'this_month'
                  ? AppColors.primaryGreen
                  : null,
            ),
          ),
          const SizedBox(width: 8),

          // This Year FilterChip
          FilterChip(
            selected: state.dateFilterMode == 'this_year',
            avatar: const Icon(
              Icons.calendar_today,
              size: 14,
              color: AppColors.primaryGreen,
            ),
            label: const Text('ယခုနှစ် (This Year)'),
            onSelected: (_) {
              context.read<GeneralLedgerCubit>().setDateFilterMode('this_year');
            },
            selectedColor: AppColors.primaryGreen.withValues(alpha: 0.18),
            checkmarkColor: AppColors.primaryGreen,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: state.dateFilterMode == 'this_year'
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: state.dateFilterMode == 'this_year'
                  ? AppColors.primaryGreen
                  : null,
            ),
          ),
          const SizedBox(width: 10),

          Container(
            height: 20,
            width: 1,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          const SizedBox(width: 10),

          // Custom Date Range ActionChip
          ActionChip(
            avatar: Icon(
              Icons.date_range,
              size: 15,
              color: hasDateFilter ? AppColors.primaryGreen : Colors.grey,
            ),
            label: Text(
              hasDateFilter
                  ? '${state.startDate} ~ ${state.endDate}'
                  : 'စိတ်ကြိုက်ရက်စွဲ (Date Range)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: hasDateFilter ? FontWeight.bold : FontWeight.normal,
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
              onPressed: () =>
                  context.read<GeneralLedgerCubit>().clearDateFilter(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountSummaryCard(
    BuildContext context,
    GeneralLedgerState state,
    dynamic selectedAccount,
    double endingBalance,
    NumberFormat numberFormat,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, cardConstraints) {
        final isCompact = cardConstraints.maxWidth < 600;

        String filterSubtitle = '';
        if (state.dateFilterMode == 'this_month') {
          filterSubtitle = 'ယခုလ (${state.startDate} ~ ${state.endDate})';
        } else if (state.dateFilterMode == 'this_year') {
          filterSubtitle = 'ယခုနှစ် (${state.startDate} ~ ${state.endDate})';
        } else if (state.startDate != null || state.endDate != null) {
          filterSubtitle = '${state.startDate ?? ""} ~ ${state.endDate ?? ""}';
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Title & GL Code
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedAccount.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    AccountTypeBadge(type: selectedAccount.type),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GL Code: ${selectedAccount.code}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (filterSubtitle.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          filterSubtitle,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 20),

                // Metrics: Period Flow & Cumulative Ending Balance
                if (isCompact) ...[
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ကာလတွင်း လှုပ်ရှားမှု (Flow)',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 3),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  '+Dr: ${numberFormat.format(state.filteredDebitTotal)}',
                                  style: const TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                                Text(
                                  '-Cr: ${numberFormat.format(state.filteredCreditTotal)}',
                                  style: const TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.creditRose,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'လက်ကျန်ငွေ (Balance)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              CurrencyFormatter.format(endingBalance),
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.assetBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      runSpacing: 10,
                      children: [
                        Wrap(
                          spacing: 20,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildMiniMetric(
                              label: 'စုစုပေါင်း ဒက်ဘစ် (Total Dr)',
                              value:
                                  '+${numberFormat.format(state.filteredDebitTotal)}',
                              color: AppColors.primaryGreen,
                              theme: theme,
                            ),
                            _buildMiniMetric(
                              label: 'စုစုပေါင်း ခရက်ဒစ် (Total Cr)',
                              value:
                                  '-${numberFormat.format(state.filteredCreditTotal)}',
                              color: AppColors.creditRose,
                              theme: theme,
                            ),
                            if (state.startDate != null)
                              _buildMiniMetric(
                                label: 'အဖွင့်လက်ကျန် (Opening)',
                                value: CurrencyFormatter.format(
                                  state.openingBalance,
                                ),
                                color: Colors.grey,
                                theme: theme,
                              ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'လက်ကျန်ငွေ (Ending Balance)',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(endingBalance),
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.assetBlue,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniMetric({
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionHistoryCard(
    BuildContext context,
    GeneralLedgerState state,
    List<dynamic> ledgerEntries,
    int totalCount,
    NumberFormat numberFormat,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;
        final isMobile = containerWidth < 650;
        final dynamicDescWidth = (containerWidth - 440).clamp(260.0, 750.0);

        final countLabel = ledgerEntries.length < totalCount
            ? '${ledgerEntries.length} of $totalCount Records'
            : '$totalCount Records';

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: isDark
                    ? const Color(0xFF14241B)
                    : const Color(0xFFF1F5F2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'အရောင်းအဝယ်မှတ်တမ်း (Transaction History)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            countLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                        if (isMobile) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              _mobileTableView
                                  ? Icons.view_agenda_outlined
                                  : Icons.table_chart_outlined,
                              size: 18,
                            ),
                            tooltip: _mobileTableView
                                ? 'Switch to Card view'
                                : 'Switch to Table view',
                            onPressed: () {
                              setState(() {
                                _mobileTableView = !_mobileTableView;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              if (ledgerEntries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 8),
                  child: Center(
                    child: Text(
                      'ဤအကောင့်/ကာလအတွက် မှတ်တမ်းမရှိသေးပါ။ (No transactions for this account/period)',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else if (isMobile && !_mobileTableView) ...[
                // Mobile Friendly Card-Based History List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: ledgerEntries.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final e = ledgerEntries[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              e.date,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.assetBlue.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Bal: ${numberFormat.format(e.balance)}',
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.assetBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (e.debit > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '+Dr: ${numberFormat.format(e.debit)}',
                                  style: const TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ),
                            if (e.debit > 0 && e.credit > 0)
                              const SizedBox(width: 8),
                            if (e.credit > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.creditRose.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '-Cr: ${numberFormat.format(e.credit)}',
                                  style: const TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.creditRose,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                // Pagination Indicator
                if (state.hasMore)
                  _buildPaginationFooter(context, isDark)
                else if (totalCount > 20)
                  _buildEndOfListIndicator(isDark, totalCount),
              ] else ...[
                // Full-Width Dynamic Table Layout (Tablet & Desktop, or Mobile Table mode)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: containerWidth),
                    child: DataTable(
                      headingRowHeight: 42,
                      dataRowMinHeight: 46,
                      dataRowMaxHeight: 58,
                      horizontalMargin: 16,
                      columnSpacing: 20,
                      columns: [
                        const DataColumn(
                          label: Text(
                            'Date',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: dynamicDescWidth,
                            child: const Text(
                              'Description',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const DataColumn(
                          numeric: true,
                          label: Text(
                            'Debit (+)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                        const DataColumn(
                          numeric: true,
                          label: Text(
                            'Credit (-)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.creditRose,
                            ),
                          ),
                        ),
                        const DataColumn(
                          numeric: true,
                          label: Text(
                            'Running Balance',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.assetBlue,
                            ),
                          ),
                        ),
                      ],
                      rows: ledgerEntries.map((e) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                e.date,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: dynamicDescWidth,
                                child: Text(
                                  e.description,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                e.debit > 0
                                    ? numberFormat.format(e.debit)
                                    : '-',
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                e.credit > 0
                                    ? numberFormat.format(e.credit)
                                    : '-',
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.creditRose,
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                numberFormat.format(e.balance),
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.assetBlue,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Pagination Indicator
                if (state.hasMore)
                  _buildPaginationFooter(context, isDark)
                else if (totalCount > 20)
                  _buildEndOfListIndicator(isDark, totalCount),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaginationFooter(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
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
            'နောက်ထပ် မှတ်တမ်းများ ရယူနေပါသည်... (Loading more...)',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndOfListIndicator(bool isDark, int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Text(
        'မှတ်တမ်းအားလုံး ပြသပြီးပါပြီ (All $totalCount records loaded)',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      ),
    );
  }
}
