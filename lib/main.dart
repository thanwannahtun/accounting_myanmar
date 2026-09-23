import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/bloc_utils/app_bloc_observer.dart';
import 'core/route_util/route_generator.dart';
import 'core/route_util/route_names.dart';
import 'core/theme/app_theme.dart';
import 'cubit/theme_mode/theme_mode_cubit.dart';
import 'data/repositories/account/account_local_repository.dart';
import 'data/repositories/account/account_repository_interface.dart';
import 'data/repositories/ai/ai_assistant_repository_impl.dart';
import 'data/repositories/ai/ai_assistant_repository_interface.dart';
import 'data/repositories/journal/journal_entry_local_repository.dart';
import 'data/repositories/journal/journal_entry_repository_interface.dart';
import 'data/repositories/settings/settings_local_repository.dart';
import 'data/repositories/settings/settings_repository_interface.dart';
import 'data/services/database/sqlite_database_service.dart';
import 'logic/account/account_cubit.dart';
import 'logic/ai/ai_assistant_cubit.dart';
import 'logic/journal/journal_entry_cubit.dart';
import 'logic/ledger/general_ledger_cubit.dart';
import 'logic/reports/financial_reports_cubit.dart';
import 'logic/settings/settings_cubit.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Initialize SQLite FFI for Desktop platforms (Windows, Linux, macOS)
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize SQLite local database engine (Desktop FFI / Mobile SQLite)
  await SqliteDatabaseService.instance.init();

  Bloc.observer = AppBlocObserver();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AccountRepositoryInterface>(
          create: (_) => AccountLocalRepository(SqliteDatabaseService.instance),
        ),
        RepositoryProvider<JournalEntryRepositoryInterface>(
          create: (_) => JournalEntryLocalRepository(SqliteDatabaseService.instance),
        ),
        RepositoryProvider<SettingsRepositoryInterface>(
          create: (_) => SettingsLocalRepository(SqliteDatabaseService.instance),
        ),
        RepositoryProvider<AiAssistantRepositoryInterface>(
          create: (_) => AiAssistantRepositoryImpl(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeModeCubit>(
            create: (_) => ThemeModeCubit(ThemeMode.system)..init(),
          ),
          BlocProvider<SettingsCubit>(
            create: (context) => SettingsCubit(
              settingsRepository: context.read<SettingsRepositoryInterface>(),
              accountRepository: context.read<AccountRepositoryInterface>(),
              journalRepository: context.read<JournalEntryRepositoryInterface>(),
            ),
          ),
          BlocProvider<AccountCubit>(
            create: (context) => AccountCubit(
              context.read<AccountRepositoryInterface>(),
            ),
          ),
          BlocProvider<JournalEntryCubit>(
            create: (context) => JournalEntryCubit(
              context.read<JournalEntryRepositoryInterface>(),
            ),
          ),
          BlocProvider<GeneralLedgerCubit>(
            create: (_) => GeneralLedgerCubit(),
          ),
          BlocProvider<FinancialReportsCubit>(
            create: (_) => FinancialReportsCubit(),
          ),
          BlocProvider<AiAssistantCubit>(
            create: (context) => AiAssistantCubit(
              context.read<AiAssistantRepositoryInterface>(),
            ),
          ),
        ],
        child: BlocBuilder<ThemeModeCubit, ThemeMode>(
          builder: (BuildContext context, ThemeMode state) => MaterialApp(
            title: 'Accounting Myanmar',
            navigatorKey: navigatorKey,
            themeMode: state,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            onGenerateRoute: RouteGenerator.onGenerateRoute,
            initialRoute: RouteNames.splashScreen,
            debugShowCheckedModeBanner: false,
          ),
        ),
      ),
    );
  }
}
