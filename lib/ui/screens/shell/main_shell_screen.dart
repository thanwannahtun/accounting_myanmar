import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../accounts/chart_of_accounts_screen.dart';
import '../ai_assistant/ai_assistant_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../journal/journal_entries_screen.dart';
import '../ledger/general_ledger_screen.dart';
import '../reports/financial_reports_screen.dart';
import '../settings/settings_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  void _navigateToIndex(int index, bool isWideScreen) {
    if (!isWideScreen) {
      if (index == 5) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const AiAssistantScreen()));
        return;
      }
      if (index == 6) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
        return;
      }
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 750;

        final screens = [
          DashboardScreen(
            onNavigateToJournal: () => _navigateToIndex(1, isWideScreen),
            onNavigateToReports: () => _navigateToIndex(4, isWideScreen),
            onNavigateToAi: () => _navigateToIndex(5, isWideScreen),
            onNavigateToSettings: () => _navigateToIndex(6, isWideScreen),
          ),
          const JournalEntriesScreen(),
          const ChartOfAccountsScreen(),
          const GeneralLedgerScreen(),
          const FinancialReportsScreen(),
          const AiAssistantScreen(),
          const SettingsScreen(),
        ];

        if (isWideScreen) {
          // Tablet & Desktop Sidebar Layout (All 7 Destinations)
          return Scaffold(
            resizeToAvoidBottomInset: false,
            body: Row(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: NavigationRail(
                            selectedIndex: _currentIndex,
                            onDestinationSelected: (idx) =>
                                _navigateToIndex(idx, true),
                            backgroundColor: isDark
                                ? AppColors.darkSurface
                                : AppColors.lightSurface,
                            labelType: NavigationRailLabelType.all,
                            leading: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.account_balance,
                                      color: AppColors.primaryGreen,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Accounting\nMyanmar',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          height: 1.2,
                                          letterSpacing: 0.2,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            destinations: const [
                              NavigationRailDestination(
                                icon: Icon(Icons.dashboard_outlined),
                                selectedIcon: Icon(Icons.dashboard),
                                label: Text('Dashboard'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.swap_horiz_outlined),
                                selectedIcon: Icon(Icons.swap_horiz),
                                label: Text('Entries'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.menu_book_outlined),
                                selectedIcon: Icon(Icons.menu_book),
                                label: Text('Accounts'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.format_list_numbered_outlined),
                                selectedIcon: Icon(Icons.format_list_numbered),
                                label: Text('Ledger'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.bar_chart_outlined),
                                selectedIcon: Icon(Icons.bar_chart),
                                label: Text('Reports'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.smart_toy_outlined),
                                selectedIcon: Icon(Icons.smart_toy),
                                label: Text('AI Assistant'),
                              ),
                              NavigationRailDestination(
                                icon: Icon(Icons.settings_outlined),
                                selectedIcon: Icon(Icons.settings),
                                label: Text('Settings'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: screens[_currentIndex]),
              ],
            ),
          );
        }

        // Mobile Layout with 5 Proportional Destinations
        return Scaffold(
          drawer: Drawer(
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard
                          : AppColors.lightNeutralContainer,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            color: AppColors.primaryGreen,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Accounting Myanmar',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ဘဏ္ဍာရေး စာရင်းကိုင် စနစ်',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        ListTile(
                          leading: const Icon(Icons.dashboard_outlined),
                          title: const Text('Dashboard (ပင်မဒက်ရှ်ဘုတ်)'),
                          selected: _currentIndex == 0,
                          onTap: () {
                            Navigator.of(context).pop();
                            _navigateToIndex(0, false);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.swap_horiz_outlined),
                          title: const Text('Journal Entries (နေ့စဉ်စာရင်း)'),
                          selected: _currentIndex == 1,
                          onTap: () {
                            Navigator.of(context).pop();
                            _navigateToIndex(1, false);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.menu_book_outlined),
                          title: const Text('Chart of Accounts (စာရင်းဇယား)'),
                          selected: _currentIndex == 2,
                          onTap: () {
                            Navigator.of(context).pop();
                            _navigateToIndex(2, false);
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.format_list_numbered_outlined,
                          ),
                          title: const Text('General Ledger (အထွေထွေ လယ်ဂျာ)'),
                          selected: _currentIndex == 3,
                          onTap: () {
                            Navigator.of(context).pop();
                            _navigateToIndex(3, false);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.bar_chart_outlined),
                          title: const Text('Financial Reports (အစီရင်ခံစာ)'),
                          selected: _currentIndex == 4,
                          onTap: () {
                            Navigator.of(context).pop();
                            _navigateToIndex(4, false);
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.smart_toy_outlined,
                            color: AppColors.primaryGreen,
                          ),
                          title: const Text('AI Assistant (AI လက်ထောက်)'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'AI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            _navigateToIndex(5, false);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.settings_outlined),
                          title: const Text('Settings (ဆက်တင်များ)'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _navigateToIndex(6, false);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: screens[_currentIndex.clamp(0, 4)],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex.clamp(0, 4),
            onDestinationSelected: (idx) => _navigateToIndex(idx, false),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.swap_horiz_outlined),
                selectedIcon: Icon(Icons.swap_horiz),
                label: 'Entries',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Accounts',
              ),
              NavigationDestination(
                icon: Icon(Icons.format_list_numbered_outlined),
                selectedIcon: Icon(Icons.format_list_numbered),
                label: 'Ledger',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Reports',
              ),
            ],
          ),
        );
      },
    );
  }
}
