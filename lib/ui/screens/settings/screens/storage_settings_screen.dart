import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/services/database/sqlite_database_service.dart';
import '../../../../data/services/export/export_service.dart';
import '../../../../logic/account/account_cubit.dart';
import '../../../../logic/cash_flow/cash_flow_cubit.dart';
import '../../../../logic/journal/journal_entry_cubit.dart';
import '../../../../logic/ledger/general_ledger_cubit.dart';
import '../../../../logic/reports/financial_reports_cubit.dart';
import '../../../../logic/settings/settings_cubit.dart';
import '../../../../logic/settings/settings_state.dart';
import '../../../widgets/export_dialog.dart';

class StorageSettingsScreen extends StatelessWidget {
  const StorageSettingsScreen({super.key});

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> _refreshAllCubits(BuildContext context) async {
    final accountCubit = context.read<AccountCubit>();
    final journalCubit = context.read<JournalEntryCubit>();
    final ledgerCubit = context.read<GeneralLedgerCubit>();
    final reportsCubit = context.read<FinancialReportsCubit>();
    final cashFlowCubit = context.read<CashFlowCubit>();
    final settingsCubit = context.read<SettingsCubit>();

    await accountCubit.loadAccounts();
    await journalCubit.loadJournalEntries();
    await settingsCubit.refreshDatabaseStats();

    final updatedAccounts = accountCubit.state.accounts;
    final updatedEntries = journalCubit.state.entries;

    ledgerCubit.refresh(
      accounts: updatedAccounts,
      transactions: updatedEntries,
    );
    reportsCubit.recompute(
      accounts: updatedAccounts,
      transactions: updatedEntries,
    );
    cashFlowCubit.updateData(
      accounts: updatedAccounts,
      transactions: updatedEntries,
    );
  }

  Future<void> _handleLoadSampleData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'သတိပြုရန် (Warning)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'နမူနာဒေတာများ ထည့်သွင်းပါက လက်ရှိဒေတာများနှင့် ပေါင်းစပ်ခြင်း သို့မဟုတ် ထပ်တူကျသော အကောင့်နံပါတ်များအပေါ် အစားထိုးခြင်း (Override / Erase) ဖြစ်ပေါ်နိုင်ပါသည်။',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 12),
            Text(
              'အရေးကြီးသည်: မိမိ၏ လက်ရှိစာရင်းများ မပျောက်ပျက်စေရန် မထည့်သွင်းမီ "Export Database Backup" ဖြင့် ကြိုတင် အရန်သိမ်းဆည်းထားရန် အထူးလိုအပ်ပါသည်။',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'နမူနာဒေတာများကို အမှန်တကယ် ထည့်သွင်းလိုပါသလား?',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('မလုပ်ဆောင်ပါ (Cancel)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('နမူနာဒေတာ ထည့်သွင်းမည် (Confirm Load)'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final settingsCubit = context.read<SettingsCubit>();
      await settingsCubit.loadSampleData();
      if (context.mounted) {
        await _refreshAllCubits(context);
      }
    }
  }

  Future<void> _handleImportDatabaseBackup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'ဒေတာဘေ့စ် အစားထိုး ပြန်လည်သွင်းယူခြင်း',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ရွေးချယ်ထားသော SQLite Backup ဖိုင်ကို သွင်းယူပါက လက်ရှိ စာရင်းအချက်အလက်များအားလုံး (Chart of Accounts, Journal Entries, Settings) ကို အပြီးအပိုင် အစားထိုး (Overwrite) ပြုလုပ်ပါမည်။',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 10),
            Text(
              'သတိပြုရန်: မသွင်းယူမီ လက်ရှိဒေတာကို "Export Database Backup" ဖြင့် ဦးစွာ အရန်သိမ်းဆည်းထားရန် အထူးအကြံပြုပါသည်။',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('မလုပ်ဆောင်ပါ (Cancel)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ဖိုင်ရွေးချယ် သွင်းယူမည် (Select File)'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await context
          .read<SettingsCubit>()
          .importDatabaseBackup();
      if (success && context.mounted) {
        await _refreshAllCubits(context);
      }
    }
  }

  Future<void> _handleImportCsv(BuildContext context) async {
    final result = await context.read<SettingsCubit>().importCsvFile(
      SqliteDatabaseService.instance,
    );
    if (result != null && context.mounted) {
      await _refreshAllCubits(context);
    }
  }

  Future<void> _handleExportAccountsCsv(BuildContext context) async {
    final accounts = context.read<AccountCubit>().state.accounts;
    final printConfig = context.read<SettingsCubit>().state.printConfig;
    final res = await ExportService.instance.exportAccountsToCsv(
      accounts: accounts,
      printConfig: printConfig,
    );
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => ExportDialog(result: res),
      );
    }
  }

  Future<void> _handleExportJournalCsv(BuildContext context) async {
    final entries = context.read<JournalEntryCubit>().state.entries;
    final accounts = context.read<AccountCubit>().state.accounts;
    final printConfig = context.read<SettingsCubit>().state.printConfig;
    final res = await ExportService.instance.exportJournalEntriesToCsv(
      entries: entries,
      accounts: accounts,
      printConfig: printConfig,
    );
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => ExportDialog(result: res),
      );
    }
  }

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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: AppColors.primaryGreen,
              ),
            );
          }
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
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.sizeOf(context).width * 0.05,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Database statistics card
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
                            const Text('Database File Size:'),
                            Text(
                              _formatFileSize(state.databaseSizeBytes),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        ),
                        if (state.databasePath != null &&
                            state.databasePath!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Storage File Location:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.black26
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                  ),
                                ),
                                child: SelectableText(
                                  state.databasePath!,
                                  style: const TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text('Cloud MySQL Compatibility:'),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen.withValues(
                                  alpha: 0.12,
                                ),
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

                // 2. Main SQLite Database Backup & Restore Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.backup,
                              color: AppColors.primaryGreen,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'SQLite Database Backup & Restore',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'မိမိ၏ စာရင်းဒေတာများ မပျောက်ပျက်စေရန် အဓိက SQLite ဒေတာဘေ့စ်ဖိုင် (.db) အား အလိုရှိရာဖိုဒါသို့ Backup ထုတ်ယူနိုင်ပြီး၊ လိုအပ်သည့်အခါ Backup ဖိုင်ကို ရွေးချယ်၍ ပြန်လည်သွင်းယူ (Import) နိုင်သည်။',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryGreen,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: state.isExportingDb
                                    ? null
                                    : () => context
                                          .read<SettingsCubit>()
                                          .exportDatabaseBackup(),
                                icon: state.isExportingDb
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.upload_file, size: 18),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: const Text('Export Database Backup'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: state.isImportingDb
                                    ? null
                                    : () =>
                                          _handleImportDatabaseBackup(context),
                                icon: state.isImportingDb
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primaryGreen,
                                        ),
                                      )
                                    : const Icon(Icons.file_download, size: 18),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: const Text('Import Database Backup'),
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

                // 3. CSV Data Management Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.table_chart,
                              color: AppColors.primaryGreen,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'CSV Data Backup & Import',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Excel သို့မဟုတ် အခြားစနစ်များနှင့် တွဲဖက်သုံးနိုင်ရန် CSV ဖိုင်များ ထုတ်ယူခြင်း သို့မဟုတ် CSV ဖိုင်ရွေးချယ်ပြီး စာရင်းအသစ်များ သွင်းယူခြင်း (Import) ပြုလုပ်နိုင်သည်။',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface,
                              foregroundColor: AppColors.primaryGreen,
                              side: const BorderSide(
                                color: AppColors.primaryGreen,
                                width: 1.2,
                              ),
                            ),
                            onPressed: state.isImportingCsv
                                ? null
                                : () => _handleImportCsv(context),
                            icon: state.isImportingCsv
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primaryGreen,
                                    ),
                                  )
                                : const Icon(Icons.file_open, size: 18),
                            label: const Text(
                              'Import CSV File (CSV ဖိုင်မှ စာရင်းသွင်းယူမည်)',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _handleExportAccountsCsv(context),
                                icon: const Icon(
                                  Icons.account_balance_wallet,
                                  size: 16,
                                ),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: const Text('Export Accounts CSV'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _handleExportJournalCsv(context),
                                icon: const Icon(Icons.receipt_long, size: 16),
                                label: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: const Text('Export Journal CSV'),
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

                // 4. Sample Data Management Section with Warning
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
                          'စမ်းသပ်လေ့လာနိုင်ရန် မြန်မာစီးပွားရေးလုပ်ငန်းသုံး စာရင်းအကောင့်များနှင့် နေ့စဉ်စာရင်းသွင်းမှု နမူနာများကို ထည့်သွင်းခြင်း သို့မဟုတ် ရှင်းလင်းခြင်း ပြုလုပ်နိုင်သည်။ (သတိပြုရန်: နမူနာဒေတာ ထည့်သွင်းပါက လက်ရှိဒေတာများနှင့် ပေါင်းစပ်/အစားထိုးပါမည်)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: state.isLoadingSampleData
                                    ? null
                                    : () => _handleLoadSampleData(context),
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
                                  await settingsCubit.clearSampleData();
                                  if (context.mounted) {
                                    await _refreshAllCubits(context);
                                  }
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

                // 5. Danger Zone - Clear All Data
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: Colors.red.withValues(alpha: 0.5),
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

                            if (confirm == true && context.mounted) {
                              await settingsCubit.clearAllData();
                              if (context.mounted) {
                                await _refreshAllCubits(context);
                              }
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
