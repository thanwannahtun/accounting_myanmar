import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/account_types.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/account/account_cubit.dart';
import '../../../logic/account/account_state.dart';
import '../../../logic/journal/journal_entry_cubit.dart';
import '../../../logic/ledger/general_ledger_cubit.dart';
import '../../../logic/reports/financial_reports_cubit.dart';
import '../../widgets/account_type_badge.dart';
import 'add_account_dialog.dart';

class ChartOfAccountsScreen extends StatefulWidget {
  const ChartOfAccountsScreen({super.key});

  @override
  State<ChartOfAccountsScreen> createState() => _ChartOfAccountsScreenState();
}

class _ChartOfAccountsScreenState extends State<ChartOfAccountsScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  void _openAddAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AddAccountDialog(
        onSave:
            ({
              required String code,
              required String name,
              required String type,
            }) async {
              final accountCubit = context.read<AccountCubit>();
              final journalCubit = context.read<JournalEntryCubit>();
              final ledgerCubit = context.read<GeneralLedgerCubit>();
              final reportsCubit = context.read<FinancialReportsCubit>();

              await accountCubit.addAccount(code: code, name: name, type: type);

              final updatedAccounts = accountCubit.state.accounts;
              final transactions = journalCubit.state.entries;

              ledgerCubit.refresh(
                accounts: updatedAccounts,
                transactions: transactions,
              );
              reportsCubit.recompute(
                accounts: updatedAccounts,
                transactions: transactions,
              );
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chart of Accounts (စာရင်းဇယား)'),
        actions: [
          IconButton(
            tooltip: 'Add Account',
            onPressed: () => _openAddAccountDialog(context),
            icon: const Icon(Icons.add_circle, color: AppColors.primaryGreen),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddAccountDialog(context),
        backgroundColor: AppColors.primaryGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width * 0.05,
              vertical: 8,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by Code or Account Name...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width * 0.05,
              vertical: 4,
            ),
            child: Row(
              children: ['All', ...AccountTypes.all].map((type) {
                final isSelected = _selectedFilter == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    selectedColor: AppColors.primaryGreen.withOpacity(0.18),
                    checkmarkColor: AppColors.primaryGreen,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? AppColors.primaryGreen : null,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = type;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Accounts List
          Expanded(
            child: BlocBuilder<AccountCubit, AccountState>(
              builder: (context, state) {
                var accounts = List.of(state.accounts);
                accounts.sort((a, b) => a.code.compareTo(b.code));

                if (_selectedFilter != 'All') {
                  accounts = accounts
                      .where((a) => a.type == _selectedFilter)
                      .toList();
                }

                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  accounts = accounts.where((a) {
                    return a.code.toLowerCase().contains(q) ||
                        a.name.toLowerCase().contains(q);
                  }).toList();
                }

                if (accounts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 56,
                          color: isDark ? Colors.grey[700] : Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'အကောင့်စာရင်း မတွေ့ရှိပါ (No Accounts Found)',
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.only(
                    left: MediaQuery.sizeOf(context).width * 0.05,
                    right: MediaQuery.sizeOf(context).width * 0.05,
                    top: 8,
                    bottom: 80,
                  ),
                  itemCount: accounts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final acc = accounts[index];

                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF14241B)
                                : const Color(0xFFF1F5F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Text(
                            acc.code,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                        title: Text(
                          acc.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: AccountTypeBadge(type: acc.type),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
