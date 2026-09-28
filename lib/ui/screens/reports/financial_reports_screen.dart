import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../logic/account/account_cubit.dart';
import '../../../logic/journal/journal_entry_cubit.dart';
import '../../../logic/reports/financial_reports_cubit.dart';
import '../../../logic/reports/financial_reports_state.dart';
import '../../../logic/settings/settings_cubit.dart';
import '../../widgets/currency_formatter.dart';
import '../../widgets/export_dialog.dart';
import '../../widgets/print_preview_dialog.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final reportsCubit = context.read<FinancialReportsCubit>();
        if (reportsCubit.cachedAccounts.isEmpty ||
            reportsCubit.state.incomeStatement == null) {
          final accounts = context.read<AccountCubit>().state.accounts;
          final transactions = context.read<JournalEntryCubit>().state.entries;
          reportsCubit.recompute(
            accounts: accounts,
            transactions: transactions,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<FinancialReportsCubit, FinancialReportsState>(
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
        final incomeStatement = state.incomeStatement;
        final balanceSheet = state.balanceSheet;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Financial Reports (ဘဏ္ဍာရေး အစီရင်ခံစာ)'),
            actions: [
              // Export CSV Button
              IconButton(
                tooltip: 'Export CSV',
                icon: const Icon(
                  Icons.file_download_outlined,
                  color: AppColors.primaryGreen,
                ),
                onPressed: () async {
                  final printConfig = context
                      .read<SettingsCubit>()
                      .state
                      .printConfig;
                  final cubit = context.read<FinancialReportsCubit>();
                  final res = _tabController.index == 0
                      ? await cubit.exportIncomeStatementCsv(printConfig)
                      : await cubit.exportBalanceSheetCsv(printConfig);

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
                tooltip: 'Print Report',
                icon: const Icon(
                  Icons.print_outlined,
                  color: AppColors.primaryGreen,
                ),
                onPressed: () {
                  final printConfig = context
                      .read<SettingsCubit>()
                      .state
                      .printConfig;
                  final defaultPrinter = context
                      .read<SettingsCubit>()
                      .state
                      .defaultPrinter;
                  final cubit = context.read<FinancialReportsCubit>();
                  final doc = _tabController.index == 0
                      ? cubit.prepareIncomeStatementPrint(printConfig)
                      : cubit.prepareBalanceSheetPrint(printConfig);

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
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryGreen,
              labelColor: AppColors.primaryGreen,
              unselectedLabelColor: isDark
                  ? Colors.grey[400]
                  : Colors.grey[600],
              tabs: const [
                Tab(text: 'Income Statement (P&L)'),
                Tab(text: 'Balance Sheet'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // 1. Income Statement (P&L)
              incomeStatement == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildIncomeStatementView(
                      context,
                      incomeStatement,
                      isDark,
                      state,
                    ),

              // 2. Balance Sheet
              balanceSheet == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBalanceSheetView(
                      context,
                      balanceSheet,
                      isDark,
                      state,
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncomeStatementView(
    BuildContext context,
    dynamic isRep,
    bool isDark,
    FinancialReportsState state,
  ) {
    final theme = Theme.of(context);
    final netProfit = isRep.netProfit as double;
    final isPositive = netProfit >= 0;

    String pnlSubtitle = 'အားလုံး (All Time)';
    if (state.pnlFilterMode == 'this_month') {
      pnlSubtitle = 'ယခုလ (${state.pnlStartDate} ~ ${state.pnlEndDate})';
    } else if (state.pnlFilterMode == 'this_year') {
      pnlSubtitle = 'ယခုနှစ် (${state.pnlStartDate} ~ ${state.pnlEndDate})';
    } else if (state.pnlStartDate != null || state.pnlEndDate != null) {
      pnlSubtitle = '${state.pnlStartDate ?? ""} ~ ${state.pnlEndDate ?? ""}';
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 650;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : screenWidth * 0.05,
        vertical: isMobile ? 10 : 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // P&L Filter Bar (Compact 1-line on mobile, full row on tablet/desktop)
              _buildPnlFilterBar(context, state, isDark, pnlSubtitle),

              Card(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 14.0 : 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Revenue Section Header
                      Row(
                        children: [
                          Text(
                            '1. Revenue',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(ဝင်ငွေများ)',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 6),
                      ...isRep.revenues.map<Widget>(
                        (r) => _buildReportRow(
                          context: context,
                          code: r.account.code,
                          name: r.account.name,
                          amount: r.amount,
                        ),
                      ),
                      const Divider(height: 16),
                      _buildTotalRow(
                        context: context,
                        label: 'Total Net Revenue (စုစုပေါင်း အသားတင်ဝင်ငွေ)',
                        amount: isRep.totalRevenue,
                      ),

                      const SizedBox(height: 28),

                      // COGS Section Header
                      Row(
                        children: [
                          Text(
                            '2. COGS',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(COGS - ရောင်းကုန်ကျစရိတ်)',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 6),
                      ...isRep.costOfGoodsSold.map<Widget>(
                        (c) => _buildReportRow(
                          context: context,
                          code: c.account.code,
                          name: c.account.name,
                          amount: c.amount,
                          isNegative: true,
                        ),
                      ),
                      const Divider(height: 16),
                      _buildTotalRow(
                        context: context,
                        label: 'Total COGS (စုစုပေါင်း ရောင်းကုန်ကျစရိတ်)',
                        amount: isRep.totalCogs,
                        isNegative: true,
                      ),

                      const SizedBox(height: 14),

                      // Minimalist Gross Profit Summary Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightNeutralContainer,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: _buildTotalRow(
                          context: context,
                          label: 'Gross Profit (စုစုပေါင်း အကြမ်းအမြတ်)',
                          amount: isRep.grossProfit,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Operating Expenses Section Header
                      Row(
                        children: [
                          Text(
                            '3. Operating Expenses',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '(လုပ်ငန်းလည်ပတ်စရိတ်များ)',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 6),
                      ...isRep.operatingExpenses.map<Widget>(
                        (o) => _buildReportRow(
                          context: context,
                          code: o.account.code,
                          name: o.account.name,
                          amount: o.amount,
                          isNegative: true,
                        ),
                      ),
                      const Divider(height: 16),
                      _buildTotalRow(
                        context: context,
                        label:
                            'Total Operating Expenses (စုစုပေါင်း လည်ပတ်စရိတ်)',
                        amount: isRep.totalOperatingExpenses,
                        isNegative: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Minimalist Net Profit / Loss Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      (isPositive
                              ? AppColors.primaryGreen
                              : AppColors.creditRose)
                          .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        (isPositive
                                ? AppColors.primaryGreen
                                : AppColors.creditRose)
                            .withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPositive
                                ? 'Net Profit (အသားတင် အမြတ်)'
                                : 'Net Loss (အသားတင် အရှုံး)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isPositive
                                  ? AppColors.primaryGreen
                                  : AppColors.creditRose,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Gross Profit - Operating Expenses',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        CurrencyFormatter.format(netProfit),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isPositive
                              ? AppColors.primaryGreen
                              : AppColors.creditRose,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceSheetView(
    BuildContext context,
    dynamic bsRep,
    bool isDark,
    FinancialReportsState state,
  ) {
    final theme = Theme.of(context);
    final isBalanced = bsRep.isBalanced as bool;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 650;
    final asOfSubtitle = state.balanceSheetAsOfDate != null
        ? 'ဖြတ်တောက်ရက်စွဲ: As of ${state.balanceSheetAsOfDate}'
        : 'ရက်စွဲအထိ: လက်ရှိအထိ (All Time / Latest)';

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : screenWidth * 0.05,
        vertical: isMobile ? 10 : 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Sheet Filter Bar (Compact 1-line on mobile, full row on tablet/desktop)
              _buildBalanceSheetFilterBar(context, state, isDark, asOfSubtitle),

              // Minimalist Balance Validation Banner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color:
                      (isBalanced
                              ? AppColors.primaryGreen
                              : AppColors.creditRose)
                          .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        (isBalanced
                                ? AppColors.primaryGreen
                                : AppColors.creditRose)
                            .withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isBalanced ? Icons.check_circle : Icons.error_outline,
                      color: isBalanced
                          ? AppColors.primaryGreen
                          : AppColors.creditRose,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isBalanced
                            ? 'Balance Sheet is Balanced (လက်ကျန်ရှင်းတမ်း ညီညွတ်ပါသည် - Assets = Liabilities + Equity)'
                            : 'Balance Sheet is OUT OF BALANCE (လက်ကျန်ရှင်းတမ်း မညီပါ - စာရင်းစစ်ဆေးပါ)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isBalanced
                              ? AppColors.primaryGreen
                              : AppColors.creditRose,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Assets Section
              Card(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 14.0 : 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Assets',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(ပိုင်ဆိုင်မှုများ)',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 6),
                      ...bsRep.assets.map<Widget>(
                        (a) => _buildReportRow(
                          context: context,
                          code: a.account.code,
                          name: a.account.name,
                          amount: a.amount,
                        ),
                      ),
                      const Divider(height: 16),
                      _buildTotalRow(
                        context: context,
                        label: 'Total Assets (စုစုပေါင်း ပိုင်ဆိုင်မှု)',
                        amount: bsRep.totalAssets,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Liabilities & Equity Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Liabilities Header
                      Row(
                        children: [
                          Text(
                            'Liabilities',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(ပေးရန်တာဝန်များ)',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 6),
                      ...bsRep.liabilities.map<Widget>(
                        (l) => _buildReportRow(
                          context: context,
                          code: l.account.code,
                          name: l.account.name,
                          amount: l.amount,
                        ),
                      ),
                      const Divider(height: 16),
                      _buildTotalRow(
                        context: context,
                        label: 'Total Liabilities (စုစုပေါင်း ပေးရန်တာဝန်)',
                        amount: bsRep.totalLiabilities,
                      ),

                      const SizedBox(height: 28),

                      // Equity Header
                      Row(
                        children: [
                          Text(
                            'Equity',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(ပိုင်ရှင်အရင်းအနှီး)',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 6),
                      ...bsRep.equities.map<Widget>(
                        (eq) => _buildReportRow(
                          context: context,
                          code: eq.account.code,
                          name: eq.account.name,
                          amount: eq.amount,
                        ),
                      ),
                      _buildReportRow(
                        context: context,
                        code: 'P&L',
                        name: 'Current Period Net Income (ယခုကာလ အသားတင်အမြတ်)',
                        amount: bsRep.currentPeriodNetIncome,
                      ),
                      const Divider(height: 16),
                      _buildTotalRow(
                        context: context,
                        label: 'Total Equity (စုစုပေါင်း အရင်းအနှီး)',
                        amount:
                            bsRep.totalEquity + bsRep.currentPeriodNetIncome,
                      ),

                      const SizedBox(height: 16),

                      // Total Liabilities & Equity Summary Card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightNeutralContainer,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: _buildTotalRow(
                          context: context,
                          label: 'Total Liabilities & Equity (တာဝန်နှင့် အရင်းအနှီး စုစုပေါင်း)',
                          amount: bsRep.totalLiabilitiesAndEquity,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportRow({
    required BuildContext context,
    required String code,
    required String name,
    required double amount,
    bool isNegative = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF14241B)
                        : const Color(0xFFF1F5F2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${isNegative ? '-' : ''}${CurrencyFormatter.format(amount)}',
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isNegative ? AppColors.creditRose : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow({
    required BuildContext context,
    required String label,
    required double amount,
    bool isNegative = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${isNegative ? '-' : ''}${CurrencyFormatter.format(amount)}',
          style: const TextStyle(
            fontFamily: 'Courier',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPnlFilterBar(
    BuildContext context,
    FinancialReportsState state,
    bool isDark,
    String pnlSubtitle,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 650;
    final hasDateFilter =
        state.pnlFilterMode == 'custom' ||
        (state.pnlStartDate != null && state.pnlFilterMode != 'all');

    if (isMobile) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _showPnlFilterBottomSheet(context, state, isDark),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: hasDateFilter
                        ? AppColors.primaryGreen.withValues(alpha: 0.12)
                        : (isDark
                              ? AppColors.darkCard
                              : AppColors.lightSurface),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasDateFilter
                          ? AppColors.primaryGreen.withValues(alpha: 0.4)
                          : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: hasDateFilter
                            ? AppColors.primaryGreen
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ကာလ: $pnlSubtitle',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: hasDateFilter
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: hasDateFilter
                                ? AppColors.primaryGreen
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: hasDateFilter
                            ? AppColors.primaryGreen
                            : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasDateFilter) ...[
              const SizedBox(width: 6),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Clear Filter',
                icon: const Icon(Icons.cancel, size: 18, color: Colors.grey),
                onPressed: () =>
                    context.read<FinancialReportsCubit>().clearPnlFilter(),
              ),
            ],
          ],
        ),
      );
    }

    // Tablet & Desktop: Horizontal chips row
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // All FilterChip
            FilterChip(
              selected: state.pnlFilterMode == 'all',
              label: const Text('အားလုံး (All Time)'),
              onSelected: (_) {
                context.read<FinancialReportsCubit>().clearPnlFilter();
              },
              selectedColor: AppColors.primaryGreen.withValues(alpha: 0.18),
              checkmarkColor: AppColors.primaryGreen,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: state.pnlFilterMode == 'all'
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: state.pnlFilterMode == 'all'
                    ? AppColors.primaryGreen
                    : null,
              ),
            ),
            const SizedBox(width: 8),

            // This Month FilterChip
            FilterChip(
              selected: state.pnlFilterMode == 'this_month',
              avatar: const Icon(
                Icons.calendar_view_month,
                size: 14,
                color: AppColors.primaryGreen,
              ),
              label: const Text('ယခုလ (This Month)'),
              onSelected: (_) {
                context.read<FinancialReportsCubit>().setPnlFilterMode(
                  'this_month',
                );
              },
              selectedColor: AppColors.primaryGreen.withValues(alpha: 0.18),
              checkmarkColor: AppColors.primaryGreen,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: state.pnlFilterMode == 'this_month'
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: state.pnlFilterMode == 'this_month'
                    ? AppColors.primaryGreen
                    : null,
              ),
            ),
            const SizedBox(width: 8),

            // This Year FilterChip
            FilterChip(
              selected: state.pnlFilterMode == 'this_year',
              avatar: const Icon(
                Icons.calendar_today,
                size: 14,
                color: AppColors.primaryGreen,
              ),
              label: const Text('ယခုနှစ် (This Year)'),
              onSelected: (_) {
                context.read<FinancialReportsCubit>().setPnlFilterMode(
                  'this_year',
                );
              },
              selectedColor: AppColors.primaryGreen.withValues(alpha: 0.18),
              checkmarkColor: AppColors.primaryGreen,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: state.pnlFilterMode == 'this_year'
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: state.pnlFilterMode == 'this_year'
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
                    ? '${state.pnlStartDate} ~ ${state.pnlEndDate}'
                    : 'စိတ်ကြိုက်ရက်စွဲ (Date Range)',
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
              onPressed: () => _pickPnlDateRange(context, state),
            ),
            if (hasDateFilter) ...[
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                tooltip: 'Clear Filter',
                icon: const Icon(Icons.cancel, size: 16, color: Colors.grey),
                onPressed: () =>
                    context.read<FinancialReportsCubit>().clearPnlFilter(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPnlFilterBottomSheet(
    BuildContext context,
    FinancialReportsState state,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'ကာလအပိုင်းအခြား ရွေးချယ်ပါ (Filter Period)',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (state.pnlFilterMode != 'all')
                        TextButton(
                          onPressed: () {
                            context
                                .read<FinancialReportsCubit>()
                                .clearPnlFilter();
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: AppColors.creditRose,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.all_inclusive,
                    color: AppColors.primaryGreen,
                  ),
                  title: const Text('အားလုံး (All Time)'),
                  trailing: state.pnlFilterMode == 'all'
                      ? const Icon(Icons.check, color: AppColors.primaryGreen)
                      : null,
                  onTap: () {
                    context.read<FinancialReportsCubit>().clearPnlFilter();
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.calendar_view_month,
                    color: AppColors.primaryGreen,
                  ),
                  title: const Text('ယခုလ (This Month)'),
                  trailing: state.pnlFilterMode == 'this_month'
                      ? const Icon(Icons.check, color: AppColors.primaryGreen)
                      : null,
                  onTap: () {
                    context.read<FinancialReportsCubit>().setPnlFilterMode(
                      'this_month',
                    );
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.calendar_today,
                    color: AppColors.primaryGreen,
                  ),
                  title: const Text('ယခုနှစ် (This Year)'),
                  trailing: state.pnlFilterMode == 'this_year'
                      ? const Icon(Icons.check, color: AppColors.primaryGreen)
                      : null,
                  onTap: () {
                    context.read<FinancialReportsCubit>().setPnlFilterMode(
                      'this_year',
                    );
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.date_range,
                    color: AppColors.primaryGreen,
                  ),
                  title: Text(
                    state.pnlFilterMode == 'custom' &&
                            state.pnlStartDate != null
                        ? 'စိတ်ကြိုက်: ${state.pnlStartDate} ~ ${state.pnlEndDate}'
                        : 'စိတ်ကြိုက်ရက်စွဲ (Custom Date Range)...',
                  ),
                  trailing: state.pnlFilterMode == 'custom'
                      ? const Icon(Icons.check, color: AppColors.primaryGreen)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickPnlDateRange(context, state);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickPnlDateRange(
    BuildContext context,
    FinancialReportsState state,
  ) async {
    DateTime initialStart = DateTime.now();
    DateTime initialEnd = DateTime.now();

    if (state.pnlStartDate != null) {
      initialStart = DateTime.tryParse(state.pnlStartDate!) ?? initialStart;
    }
    if (state.pnlEndDate != null) {
      initialEnd = DateTime.tryParse(state.pnlEndDate!) ?? initialEnd;
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: DateTimeRange(
        start: initialStart.isAfter(initialEnd) ? initialEnd : initialStart,
        end: initialEnd,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      final startStr = picked.start.toIso8601String().substring(0, 10);
      final endStr = picked.end.toIso8601String().substring(0, 10);
      context.read<FinancialReportsCubit>().setPnlCustomDateRange(
        startStr,
        endStr,
      );
    }
  }

  Widget _buildBalanceSheetFilterBar(
    BuildContext context,
    FinancialReportsState state,
    bool isDark,
    String asOfSubtitle,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 650;
    final hasAsOfDate = state.balanceSheetAsOfDate != null;

    if (isMobile) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () =>
                    _showBalanceSheetFilterBottomSheet(context, state, isDark),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: hasAsOfDate
                        ? AppColors.primaryGreen.withValues(alpha: 0.12)
                        : (isDark
                              ? AppColors.darkCard
                              : AppColors.lightSurface),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasAsOfDate
                          ? AppColors.primaryGreen.withValues(alpha: 0.4)
                          : (isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 14,
                        color: hasAsOfDate
                            ? AppColors.primaryGreen
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          asOfSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: hasAsOfDate
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: hasAsOfDate ? AppColors.primaryGreen : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 18,
                        color: hasAsOfDate
                            ? AppColors.primaryGreen
                            : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasAsOfDate) ...[
              const SizedBox(width: 6),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Reset to Latest',
                icon: const Icon(Icons.cancel, size: 18, color: Colors.grey),
                onPressed: () => context
                    .read<FinancialReportsCubit>()
                    .clearBalanceSheetDate(),
              ),
            ],
          ],
        ),
      );
    }

    // Tablet & Desktop: Horizontal chips row
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // All Time / Latest FilterChip
            FilterChip(
              selected: !hasAsOfDate,
              label: const Text('လက်ရှိအထိ (All Time / Latest)'),
              onSelected: (_) {
                context.read<FinancialReportsCubit>().clearBalanceSheetDate();
              },
              selectedColor: AppColors.primaryGreen.withValues(alpha: 0.18),
              checkmarkColor: AppColors.primaryGreen,
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: !hasAsOfDate ? FontWeight.bold : FontWeight.normal,
                color: !hasAsOfDate ? AppColors.primaryGreen : null,
              ),
            ),
            const SizedBox(width: 10),

            Container(
              height: 20,
              width: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            const SizedBox(width: 10),

            // As of Date ActionChip
            ActionChip(
              avatar: Icon(
                Icons.event,
                size: 15,
                color: hasAsOfDate ? AppColors.primaryGreen : Colors.grey,
              ),
              label: Text(
                hasAsOfDate
                    ? 'ရက်စွဲအထိ (As of ${state.balanceSheetAsOfDate})'
                    : 'ရက်စွဲဖြတ်တောက်ရန် (Cut-off Date)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: hasAsOfDate ? FontWeight.bold : FontWeight.normal,
                  color: hasAsOfDate ? AppColors.primaryGreen : null,
                ),
              ),
              backgroundColor: hasAsOfDate
                  ? AppColors.primaryGreen.withValues(alpha: 0.12)
                  : null,
              side: hasAsOfDate
                  ? const BorderSide(color: AppColors.primaryGreen)
                  : null,
              onPressed: () => _pickBalanceSheetDate(context, state),
            ),
            if (hasAsOfDate) ...[
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                tooltip: 'Reset to Today / All Time',
                icon: const Icon(Icons.cancel, size: 16, color: Colors.grey),
                onPressed: () => context
                    .read<FinancialReportsCubit>()
                    .clearBalanceSheetDate(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBalanceSheetFilterBottomSheet(
    BuildContext context,
    FinancialReportsState state,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      builder: (ctx) {
        final hasAsOfDate = state.balanceSheetAsOfDate != null;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ဖြတ်တောက်ရက်စွဲ (As of Cut-off Date)',
                        style: Theme.of(context).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (hasAsOfDate)
                        TextButton(
                          onPressed: () {
                            context
                                .read<FinancialReportsCubit>()
                                .clearBalanceSheetDate();
                            Navigator.pop(ctx);
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(
                              color: AppColors.creditRose,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.all_inclusive,
                    color: AppColors.primaryGreen,
                  ),
                  title: const Text('လက်ရှိအထိ (All Time / Latest)'),
                  trailing: !hasAsOfDate
                      ? const Icon(Icons.check, color: AppColors.primaryGreen)
                      : null,
                  onTap: () {
                    context
                        .read<FinancialReportsCubit>()
                        .clearBalanceSheetDate();
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.event,
                    color: AppColors.primaryGreen,
                  ),
                  title: Text(
                    hasAsOfDate
                        ? 'ရက်စွဲအထိ: As of ${state.balanceSheetAsOfDate}'
                        : 'ရက်စွဲဖြတ်တောက်ရန် (Pick Cut-off Date)...',
                  ),
                  trailing: hasAsOfDate
                      ? const Icon(Icons.check, color: AppColors.primaryGreen)
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickBalanceSheetDate(context, state);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickBalanceSheetDate(
    BuildContext context,
    FinancialReportsState state,
  ) async {
    DateTime initial = DateTime.now();
    if (state.balanceSheetAsOfDate != null) {
      initial = DateTime.tryParse(state.balanceSheetAsOfDate!) ?? initial;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      final dateStr = picked.toIso8601String().substring(0, 10);
      context.read<FinancialReportsCubit>().setBalanceSheetAsOfDate(dateStr);
    }
  }
}
