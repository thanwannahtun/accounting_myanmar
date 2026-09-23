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

  void _navigateToIndex(int index) {
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
            onNavigateToJournal: () => _navigateToIndex(1),
            onNavigateToReports: () => _navigateToIndex(4),
            onNavigateToAi: () => _navigateToIndex(5),
          ),
          const JournalEntriesScreen(),
          const ChartOfAccountsScreen(),
          const GeneralLedgerScreen(),
          const FinancialReportsScreen(),
          const AiAssistantScreen(),
          const SettingsScreen(),
        ];

        if (isWideScreen) {
          // Tablet & Desktop Sidebar Layout
          return Scaffold(
            body: Row(
              children: [
                // NavigationRail Sidebar
                NavigationRail(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _navigateToIndex,
                  backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.account_balance, color: AppColors.primaryGreen, size: 28),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'LedgerPro',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard, color: AppColors.primaryGreen),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.swap_horiz_outlined),
                      selectedIcon: Icon(Icons.swap_horiz, color: AppColors.primaryGreen),
                      label: Text('Entries'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.menu_book_outlined),
                      selectedIcon: Icon(Icons.menu_book, color: AppColors.primaryGreen),
                      label: Text('Accounts'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.format_list_numbered_outlined),
                      selectedIcon: Icon(Icons.format_list_numbered, color: AppColors.primaryGreen),
                      label: Text('Ledger'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bar_chart_outlined),
                      selectedIcon: Icon(Icons.bar_chart, color: AppColors.primaryGreen),
                      label: Text('Reports'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.smart_toy_outlined),
                      selectedIcon: Icon(Icons.smart_toy, color: AppColors.primaryGreen),
                      label: Text('AI Assistant'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings, color: AppColors.primaryGreen),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                // Main Content View
                Expanded(
                  child: screens[_currentIndex],
                ),
              ],
            ),
          );
        }

        // Mobile Layout with Bottom Navigation Bar
        return Scaffold(
          body: screens[_currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex > 4 ? 0 : _currentIndex,
            onDestinationSelected: (idx) {
              if (idx == 5) {
                _navigateToIndex(6); // Settings
              } else {
                _navigateToIndex(idx);
              }
            },
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
                icon: Icon(Icons.format_list_numbered_outlined),
                selectedIcon: Icon(Icons.format_list_numbered),
                label: 'Ledger',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Reports',
              ),
              NavigationDestination(
                icon: Icon(Icons.smart_toy_outlined),
                selectedIcon: Icon(Icons.smart_toy),
                label: 'AI Chat',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
