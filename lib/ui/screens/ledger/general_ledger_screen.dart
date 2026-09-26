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
  bool _mobileTableView = false;

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
        final ledgerEntries = state.entries;
        final endingBalance = state.endingBalance;

        return Scaffold(
          appBar: AppBar(
            title: const Text('General Ledger (အထွေထွေ လယ်ဂျာ)'),
            actions: [
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
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width * 0.05,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                const SizedBox(height: 16),

                // Responsive Account Summary Card (No overflow on mobile or wide screens)
                if (selectedAccount != null)
                  LayoutBuilder(
                    builder: (context, cardConstraints) {
                      final isCompact = cardConstraints.maxWidth < 500;

                      if (isCompact) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        selectedAccount.name,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AccountTypeBadge(
                                      type: selectedAccount.type,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'GL Code: ${selectedAccount.code}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'လက်ကျန်ငွေ (Ending Balance)',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(endingBalance),
                                      style: const TextStyle(
                                        fontFamily: 'Courier',
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.assetBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Wider screen layout
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            selectedAccount.name,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        AccountTypeBadge(
                                          type: selectedAccount.type,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'GL Code: ${selectedAccount.code}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
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
                      );
                    },
                  ),

                const SizedBox(height: 20),

                // Responsive Transaction History Card
                LayoutBuilder(
                  builder: (context, constraints) {
                    final containerWidth = constraints.maxWidth;
                    final isMobile = containerWidth < 650;
                    // Dynamically calculate description width so it fills available space
                    final dynamicDescWidth = (containerWidth - 440).clamp(
                      260.0,
                      750.0,
                    );

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
                                        color: Colors.grey.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${ledgerEntries.length} Records',
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
                                            _mobileTableView =
                                                !_mobileTableView;
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
                              padding: EdgeInsets.symmetric(vertical: 40.0),
                              child: Center(
                                child: Text(
                                  'ဤအကောင့်အတွက် မှတ်တမ်းမရှိသေးပါ။ (No transactions for this account)',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else if (isMobile && !_mobileTableView)
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                            color: AppColors.assetBlue
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
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
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
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
                                              color: AppColors.primaryGreen
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
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
                                              color: AppColors.creditRose
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
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
                            )
                          else
                            // Full-Width Dynamic Table Layout (Tablet & Desktop, or Mobile Table mode)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: containerWidth,
                                ),
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
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          SizedBox(
                                            width: dynamicDescWidth,
                                            child: Text(
                                              e.description,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
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
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
