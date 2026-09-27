import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/route_util/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../logic/account/account_cubit.dart';
import '../../../logic/ai/ai_assistant_cubit.dart';
import '../../../logic/journal/journal_entry_cubit.dart';
import '../../../logic/ledger/general_ledger_cubit.dart';
import '../../../logic/reports/financial_reports_cubit.dart';
import '../../../logic/settings/settings_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final settingsCubit = context.read<SettingsCubit>();
    final accountCubit = context.read<AccountCubit>();
    final journalCubit = context.read<JournalEntryCubit>();
    final aiCubit = context.read<AiAssistantCubit>();

    await settingsCubit.init();
    await accountCubit.loadAccounts();
    await journalCubit.loadJournalEntries();
    await aiCubit.init();

    if (!mounted) return;

    final accounts = accountCubit.state.accounts;
    final transactions = journalCubit.state.entries;

    context.read<GeneralLedgerCubit>().refresh(
      accounts: accounts,
      transactions: transactions,
    );
    context.read<FinancialReportsCubit>().recompute(
      accounts: accounts,
      transactions: transactions,
    );

    final isFirstTime = settingsCubit.state.isFirstTime;
    if (isFirstTime) {
      _showFirstTimeDialog();
    } else {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(RouteNames.app, (route) => false);
    }
  }

  void _showFirstTimeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.auto_stories, color: AppColors.primaryGreen, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'နမူနာဒေတာများ ထည့်သွင်းမလား?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'Accounting Myanmar အက်ပ်ကို အစမ်းလေ့လာနိုင်ရန်အတွက် မြန်မာစီးပွားရေးလုပ်ငန်းသုံး အကောင့် ၁၃ ခုနှင့် စာရင်းရေးသွင်းမှု (Double-Entry) နမူနာ ၁၄ ခုကို ထည့်သွင်းပေးထားပါသည်။\n\nနမူနာဒေတာများကို အခုချက်ချင်း ထည့်သွင်းလိုပါသလား?',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await context
                    .read<SettingsCubit>()
                    .markFirstTimePromptCompleted();
                if (!mounted) return;
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(RouteNames.app, (route) => false);
              },
              child: const Text('အသစ်စတင်မည် (Start Fresh)'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _performSampleDataLoad();
              },
              child: const Text('နမူနာဒေတာ ထည့်သွင်းမည် (Load Sample)'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performSampleDataLoad() async {
    // Show non-dismissible loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryGreen),
                  SizedBox(height: 20),
                  Text(
                    'Loading sample data...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'နမူနာ စာရင်းအင်းဒေတာများ ထည့်သွင်းနေပါသည်...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    final settingsCubit = context.read<SettingsCubit>();
    final accountCubit = context.read<AccountCubit>();
    final journalCubit = context.read<JournalEntryCubit>();

    await settingsCubit.loadSampleData();
    await accountCubit.loadAccounts();
    await journalCubit.loadJournalEntries();

    if (!mounted) return;

    final accounts = accountCubit.state.accounts;
    final transactions = journalCubit.state.entries;

    context.read<GeneralLedgerCubit>().refresh(
      accounts: accounts,
      transactions: transactions,
    );
    context.read<FinancialReportsCubit>().recompute(
      accounts: accounts,
      transactions: transactions,
    );

    // Dismiss loading dialog and navigate to app
    Navigator.of(context, rootNavigator: true).pop();
    Navigator.of(context).pushReplacementNamed(RouteNames.app);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(35),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                "assets/images/app_icon_foreground.png",
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Accounting Myanmar',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'မြန်မာ့ စာရင်းကိုင် စနစ် (Double-Entry Bookkeeping)',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
