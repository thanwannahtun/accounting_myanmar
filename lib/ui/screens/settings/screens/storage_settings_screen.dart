import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../logic/account/account_cubit.dart';
import '../../../../logic/journal/journal_entry_cubit.dart';
import '../../../../logic/ledger/general_ledger_cubit.dart';
import '../../../../logic/reports/financial_reports_cubit.dart';
import '../../../../logic/settings/settings_cubit.dart';
import '../../../../logic/settings/settings_state.dart';

class StorageSettingsScreen extends StatelessWidget {
  const StorageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage & Database (ဒေတာဘေ့စ် စီမံခန့်ခွဲမှု)'),
      ),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          if (state.message != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width * 0.05,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Database statistics card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.storage,
                              color: AppColors.primaryGreen,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Local SQLite Database Status',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Chart of Accounts:'),
                            Text(
                              '${state.totalAccountsCount} Accounts',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Journal Entries:'),
                            Text(
                              '${state.totalTransactionsCount} Transactions',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: const Text('Cloud MySQL Compatibility:'),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Ready / Compatible',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Sample Data Management Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'နမူနာဒေတာ စီမံခန့်ခွဲမှု (Sample Data)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'စမ်းသပ်လေ့လာနိုင်ရန် မြန်မာစီးပွားရေးလုပ်ငန်းသုံး စာရင်းအကောင့်များနှင့် နေ့စဉ်စာရင်းသွင်းမှု နမူနာများကို ထည့်သွင်းခြင်း သို့မဟုတ် ရှင်းလင်းခြင်း ပြုလုပ်နိုင်သည်။',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: state.isLoadingSampleData
                                    ? null
                                    : () async {
                                        final settingsCubit = context
                                            .read<SettingsCubit>();
                                        final accountCubit = context
                                            .read<AccountCubit>();
                                        final journalCubit = context
                                            .read<JournalEntryCubit>();
                                        final ledgerCubit = context
                                            .read<GeneralLedgerCubit>();
                                        final reportsCubit = context
                                            .read<FinancialReportsCubit>();

                                        await settingsCubit.loadSampleData();
                                        await accountCubit.loadAccounts();
                                        await journalCubit.loadJournalEntries();

                                        final updatedAccounts =
                                            accountCubit.state.accounts;
                                        final updatedEntries =
                                            journalCubit.state.entries;

                                        ledgerCubit.refresh(
                                          accounts: updatedAccounts,
                                          transactions: updatedEntries,
                                        );
                                        reportsCubit.recompute(
                                          accounts: updatedAccounts,
                                          transactions: updatedEntries,
                                        );
                                      },
                                icon: const Icon(Icons.download, size: 18),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: const Text('Load Sample Data'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final settingsCubit = context
                                      .read<SettingsCubit>();
                                  final accountCubit = context
                                      .read<AccountCubit>();
                                  final journalCubit = context
                                      .read<JournalEntryCubit>();
                                  final ledgerCubit = context
                                      .read<GeneralLedgerCubit>();
                                  final reportsCubit = context
                                      .read<FinancialReportsCubit>();

                                  await settingsCubit.clearSampleData();
                                  await accountCubit.loadAccounts();
                                  await journalCubit.loadJournalEntries();

                                  final updatedAccounts =
                                      accountCubit.state.accounts;
                                  final updatedEntries =
                                      journalCubit.state.entries;

                                  ledgerCubit.refresh(
                                    accounts: updatedAccounts,
                                    transactions: updatedEntries,
                                  );
                                  reportsCubit.recompute(
                                    accounts: updatedAccounts,
                                    transactions: updatedEntries,
                                  );
                                },
                                icon: const Icon(
                                  Icons.cleaning_services,
                                  size: 18,
                                ),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: const Text('Clear Sample'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Danger Zone - Clear All Data
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: Colors.red.withOpacity(0.5),
                      width: 1.2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Danger Zone (အထူးသတိပြုရန်)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'ဒေတာအားလုံးကို ဖျက်ပစ်ပါက ပြန်လည်ရယူနိုင်တော့မည် မဟုတ်ပါ။ မဖျက်မီ Backup ပြုလုပ်ထားရန် အထူးလိုအပ်ပါသည်။',
                          style: TextStyle(fontSize: 12, height: 1.3),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final settingsCubit = context.read<SettingsCubit>();
                            final accountCubit = context.read<AccountCubit>();
                            final journalCubit = context
                                .read<JournalEntryCubit>();
                            final ledgerCubit = context
                                .read<GeneralLedgerCubit>();
                            final reportsCubit = context
                                .read<FinancialReportsCubit>();

                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text(
                                  'ဒေတာအားလုံး ဖျက်မည်မှာ သေချာပါသလား?',
                                ),
                                content: const Text(
                                  'စာရင်းဇယား (Chart of Accounts)၊ နေ့စဉ်အရောင်းအဝယ် (Journal Entries) နှင့် ဆက်တင်ဒေတာ အားလုံးကို အပြီးအပိုင် ရှင်းလင်းပါမည်။\n\nသတိပြုရန်: Backup ဒေတာ မရှိပါက ပြန်လည် မရရှိနိုင်ပါ။',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('မဖျက်တော့ပါ (Cancel)'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text(
                                      'အားလုံးဖျက်မည် (Clear All)',
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await settingsCubit.clearAllData();
                              await accountCubit.loadAccounts();
                              await journalCubit.loadJournalEntries();

                              ledgerCubit.refresh(
                                accounts: [],
                                transactions: [],
                              );
                              reportsCubit.recompute(
                                accounts: [],
                                transactions: [],
                              );
                            }
                          },
                          icon: const Icon(Icons.delete_forever, size: 18),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: const Text(
                              'ဒေတာအားလုံး ရှင်းလင်းမည် (Clear All Data)',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
