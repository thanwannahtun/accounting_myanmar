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

class _FinancialReportsScreenState extends State<FinancialReportsScreen> with SingleTickerProviderStateMixin {
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
            SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
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
                icon: const Icon(Icons.file_download_outlined, color: AppColors.primaryGreen),
                onPressed: () async {
                  final printConfig = context.read<SettingsCubit>().state.printConfig;
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
                icon: const Icon(Icons.print_outlined, color: AppColors.primaryGreen),
                onPressed: () {
                  final printConfig = context.read<SettingsCubit>().state.printConfig;
                  final defaultPrinter = context.read<SettingsCubit>().state.defaultPrinter;
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
              unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
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
    final netProfit = isRep.netProfit as double;
    final isPositive = netProfit >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Revenue
                  const Text('1. Revenue (ဝင်ငွေများ)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                  const SizedBox(height: 8),
                  const Divider(),
                  ...isRep.revenues.map((r) => _buildReportRow(
                        code: r.account.code,
                        name: r.account.name,
                        amount: r.amount,
                      )),
                  const Divider(),
                  _buildTotalRow('Total Net Revenue (စုစုပေါင်း အသားတင်ဝင်ငွေ)', isRep.totalRevenue, color: AppColors.primaryGreen),

                  const SizedBox(height: 24),

                  // COGS
                  const Text('2. Cost of Goods Sold (COGS - ရောင်းကုန်ကျစရိတ်)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.creditRose)),
                  const SizedBox(height: 8),
                  const Divider(),
                  ...isRep.costOfGoodsSold.map((c) => _buildReportRow(
                        code: c.account.code,
                        name: c.account.name,
                        amount: c.amount,
                        isNegative: true,
                      )),
                  const Divider(),
                  _buildTotalRow('Total COGS (စုစုပေါင်း ရောင်းကုန်ကျစရိတ်)', isRep.totalCogs, isNegative: true),

                  const SizedBox(height: 12),
                  // Gross Profit highlight
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.assetBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.assetBlue.withOpacity(0.3)),
                    ),
                    child: _buildTotalRow('Gross Profit (စုစုပေါင်း အကြမ်းအမြတ်)', isRep.grossProfit, color: AppColors.assetBlue),
                  ),

                  const SizedBox(height: 24),

                  // Operating Expenses
                  const Text('3. Operating Expenses (လုပ်ငန်းလည်ပတ်စရိတ်များ)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.creditRose)),
                  const SizedBox(height: 8),
                  const Divider(),
                  ...isRep.operatingExpenses.map((o) => _buildReportRow(
                        code: o.account.code,
                        name: o.account.name,
                        amount: o.amount,
                        isNegative: true,
                      )),
                  const Divider(),
                  _buildTotalRow('Total Operating Expenses (စုစုပေါင်း လည်ပတ်စရိတ်)', isRep.totalOperatingExpenses, isNegative: true),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Net Profit / Loss Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isPositive ? AppColors.primaryGreen : AppColors.creditRose).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isPositive ? AppColors.primaryGreen : AppColors.creditRose).withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPositive ? 'Net Profit (အသားတင် အမြတ်)' : 'Net Loss (အသားတင် အရှုံး)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? AppColors.primaryGreen : AppColors.creditRose,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Gross Profit - Operating Expenses',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ],
                ),
                Text(
                  CurrencyFormatter.format(netProfit),
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? AppColors.primaryGreen : AppColors.creditRose,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSheetView(
    BuildContext context,
    dynamic bsRep,
    bool isDark,
  ) {
    final isBalanced = bsRep.isBalanced as bool;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Validation Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: (isBalanced ? AppColors.primaryGreen : AppColors.creditRose).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (isBalanced ? AppColors.primaryGreen : AppColors.creditRose).withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isBalanced ? Icons.check_circle : Icons.error,
                  color: isBalanced ? AppColors.primaryGreen : AppColors.creditRose,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isBalanced
                        ? 'Balance Sheet is Balanced (လက်ကျန်ရှင်းတမ်း ညီညွတ်ပါသည် - Assets = Liabilities + Equity)'
                        : 'Balance Sheet is OUT OF BALANCE (လက်ကျန်ရှင်းတမ်း မညီပါ - စာရင်းစစ်ဆေးပါ)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isBalanced ? AppColors.primaryGreen : AppColors.creditRose,
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Assets (ပိုင်ဆိုင်မှုများ)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.assetBlue)),
                  const SizedBox(height: 8),
                  const Divider(),
                  ...bsRep.assets.map((a) => _buildReportRow(
                        code: a.account.code,
                        name: a.account.name,
                        amount: a.amount,
                      )),
                  const Divider(),
                  _buildTotalRow('Total Assets (စုစုပေါင်း ပိုင်ဆိုင်မှု)', bsRep.totalAssets, color: AppColors.assetBlue),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Liabilities & Equity Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Liabilities
                  const Text('Liabilities (ပေးရန်တာဝန်များ)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.creditRose)),
                  const SizedBox(height: 8),
                  const Divider(),
                  ...bsRep.liabilities.map((l) => _buildReportRow(
                        code: l.account.code,
                        name: l.account.name,
                        amount: l.amount,
                      )),
                  const Divider(),
                  _buildTotalRow('Total Liabilities (စုစုပေါင်း ပေးရန်တာဝန်)', bsRep.totalLiabilities, color: AppColors.creditRose),

                  const SizedBox(height: 24),

                  // Equity
                  const Text('Equity (ပိုင်ရှင်အရင်းအနှီး)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.equityPurple)),
                  const SizedBox(height: 8),
                  const Divider(),
                  ...bsRep.equities.map((eq) => _buildReportRow(
                        code: eq.account.code,
                        name: eq.account.name,
                        amount: eq.amount,
                      )),
                  _buildReportRow(
                    code: 'P&L',
                    name: 'Current Period Net Income (ယခုကာလ အသားတင်အမြတ်)',
                    amount: bsRep.currentPeriodNetIncome,
                  ),
                  const Divider(),
                  _buildTotalRow('Total Equity (စုစုပေါင်း အရင်းအနှီး)', bsRep.totalEquity + bsRep.currentPeriodNetIncome, color: AppColors.equityPurple),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.equityPurple.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.equityPurple.withOpacity(0.3)),
                    ),
                    child: _buildTotalRow('Total Liabilities & Equity (တာဝန်နှင့် အရင်းအနှီး စုစုပေါင်း)', bsRep.totalLiabilitiesAndEquity, color: AppColors.equityPurple),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow({
    required String code,
    required String name,
    required double amount,
    bool isNegative = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  code,
                  style: const TextStyle(fontSize: 12, fontFamily: 'Courier', color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildTotalRow(String label, double amount, {Color? color, bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
        ),
        Text(
          '${isNegative ? '-' : ''}${CurrencyFormatter.format(amount)}',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
