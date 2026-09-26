import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
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
                  : _buildIncomeStatementView(context, incomeStatement, isDark),

              // 2. Balance Sheet
              balanceSheet == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBalanceSheetView(context, balanceSheet, isDark),
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
  ) {
    final theme = Theme.of(context);
    final netProfit = isRep.netProfit as double;
    final isPositive = netProfit >= 0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width * 0.05,
        vertical: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
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
  ) {
    final theme = Theme.of(context);
    final isBalanced = bsRep.isBalanced as bool;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.sizeOf(context).width * 0.05,
        vertical: 16,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              const SizedBox(height: 16),

              // Assets Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
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
}
