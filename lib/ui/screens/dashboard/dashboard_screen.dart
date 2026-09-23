import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/reports/financial_reports_cubit.dart';
import '../../../logic/reports/financial_reports_state.dart';
import '../../widgets/currency_formatter.dart';
import '../../widgets/kpi_card.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onNavigateToJournal;
  final VoidCallback? onNavigateToReports;
  final VoidCallback? onNavigateToAi;

  const DashboardScreen({
    super.key,
    this.onNavigateToJournal,
    this.onNavigateToReports,
    this.onNavigateToAi,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<FinancialReportsCubit, FinancialReportsState>(
      builder: (context, state) {
        final metrics = state.dashboardMetrics;
        final cashFlowList = state.cashFlowTransactions;

        final revenue = metrics?.totalRevenue ?? 0.0;
        final expense = metrics?.totalExpenses ?? 0.0;
        final netProfit = metrics?.netProfit ?? 0.0;
        final assets = metrics?.totalAssets ?? 0.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard (ပင်မဒက်ရှ်ဘုတ်)'),
            actions: [
              IconButton(
                tooltip: 'AI စာရင်းကိုင် လက်ထောက်',
                onPressed: onNavigateToAi,
                icon: const Icon(Icons.smart_toy_outlined, color: AppColors.primaryGreen),
              ),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.primaryGreen,
            onRefresh: () async {
              // Trigger refresh via shell or bloc if needed
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header subtext
                  Text(
                    'လစဉ် အမြတ်/အရှုံး နှင့် ဘဏ္ဍာရေး အနှစ်ချုပ်',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Responsive KPI Cards Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 700;
                      final isMedium = constraints.maxWidth >= 500 && !isWide;

                      int crossAxisCount = 1;
                      if (isWide) {
                        crossAxisCount = 4;
                      } else if (isMedium) {
                        crossAxisCount = 2;
                      }

                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: isWide ? 1.6 : (isMedium ? 1.8 : 2.4),
                        children: [
                          KpiCard(
                            title: 'စုစုပေါင်း ဝင်ငွေ (Total Revenue)',
                            value: CurrencyFormatter.format(revenue),
                            icon: Icons.trending_up,
                            iconColor: AppColors.primaryGreen,
                            valueColor: AppColors.primaryGreen,
                          ),
                          KpiCard(
                            title: 'စုစုပေါင်း အသုံးစရိတ် (Total Expenses)',
                            value: CurrencyFormatter.format(expense),
                            icon: Icons.trending_down,
                            iconColor: AppColors.creditRose,
                            valueColor: AppColors.creditRose,
                          ),
                          KpiCard(
                            title: 'အသားတင် အမြတ်/အရှုံး (Net Profit)',
                            value: CurrencyFormatter.format(netProfit),
                            icon: Icons.monetization_on_outlined,
                            iconColor: netProfit >= 0 ? AppColors.primaryGreen : AppColors.creditRose,
                            valueColor: netProfit >= 0 ? AppColors.primaryGreen : AppColors.creditRose,
                          ),
                          KpiCard(
                            title: 'စုစုပေါင်း ပိုင်ဆိုင်မှု (Total Assets)',
                            value: CurrencyFormatter.format(assets),
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: AppColors.assetBlue,
                            valueColor: AppColors.assetBlue,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Quick Action Buttons
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onNavigateToJournal,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('New Entry', maxLines: 1),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: onNavigateToReports,
                              icon: const Icon(Icons.bar_chart, size: 18),
                              label: const Text('Reports', maxLines: 1),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Cash Flow Activity (Transactions affecting cash account a1000)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ငွေသားလှုပ်ရှားမှု စာရင်း (Cash Flow Activity)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.assetBlue.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Cash / Bank',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.assetBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          if (cashFlowList.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(
                                child: Text(
                                  'ငွေသားလှုပ်ရှားမှု စာရင်း မရှိသေးပါ။ (No cash transactions found)',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: cashFlowList.length > 8 ? 8 : cashFlowList.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final tx = cashFlowList[index];
                                final cashLine = tx.lines.firstWhere(
                                  (l) => l.accountId == 'a1000' || l.accountId.toLowerCase().contains('cash'),
                                );
                                final isPositive = cashLine.debit > 0;
                                final amount = isPositive ? cashLine.debit : cashLine.credit;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                                  leading: CircleAvatar(
                                    backgroundColor: (isPositive ? AppColors.primaryGreen : AppColors.creditRose)
                                        .withOpacity(0.12),
                                    child: Icon(
                                      isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: isPositive ? AppColors.primaryGreen : AppColors.creditRose,
                                      size: 18,
                                    ),
                                  ),
                                  title: Text(
                                    tx.description,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    tx.date,
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                  trailing: Text(
                                    '${isPositive ? '+' : '-'}${CurrencyFormatter.format(amount)}',
                                    style: TextStyle(
                                      fontFamily: 'Courier',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isPositive ? AppColors.primaryGreen : AppColors.creditRose,
                                    ),
                                  ),
                                );
                              },
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
      },
    );
  }
}
