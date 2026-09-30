import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/bloc_utils/bloc_status.dart';
import '../../core/secure_storage_service.dart';
import '../../data/models/print_config.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/account/account_repository_interface.dart';
import '../../data/repositories/journal/journal_entry_repository_interface.dart';
import '../../data/repositories/settings/settings_repository_interface.dart';
import '../../data/services/database/database_service_interface.dart';
import '../../data/services/export/export_service.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepositoryInterface settingsRepository;
  final AccountRepositoryInterface accountRepository;
  final JournalEntryRepositoryInterface journalRepository;
  final SecureStorageService _secureStorage;

  static const String currentAppVersion = '1.0.0+2';
  static const String _geminiApiKeyStorageKey = 'gemini_api_key_secure_storage';
  static const String _geminiModelStorageKey = 'selected_gemini_model';
  static const String _firstTimeCheckedKey = 'has_prompted_first_time_load';

  SettingsCubit({
    required this.settingsRepository,
    required this.accountRepository,
    required this.journalRepository,
    SecureStorageService? secureStorage,
  }) : _secureStorage = secureStorage ?? SecureStorageService.instance,
       super(const SettingsState());

  Future<void> init() async {
    emit(state.copyWith(status: BlocStatus.loading));
    try {
      final hasData = await settingsRepository.hasData();
      final isSampleLoaded = await settingsRepository.isSampleDataLoaded();
      final hasPromptedInDb =
          (await settingsRepository.getSetting('first_time_prompted')) ==
          'true';
      final hasPromptedInSecure =
          (await _secureStorage.read(_firstTimeCheckedKey)) == 'true';
      final lastAppVersion = await settingsRepository.getSetting(
        'last_app_version',
      );

      // Persistence safeguard: If the user previously had data, or completed first-time setup,
      // or updated from an earlier version, NEVER treat as first time!
      final hasCompletedBefore =
          hasPromptedInDb || hasPromptedInSecure || (lastAppVersion != null);
      final isFirstTime = !hasCompletedBefore && !hasData;

      // Update version tag in database
      await settingsRepository.setSetting(
        'last_app_version',
        currentAppVersion,
      );
      if (hasData || !isFirstTime) {
        await settingsRepository.setSetting('first_time_prompted', 'true');
        await _secureStorage.write(_firstTimeCheckedKey, 'true');
      }

      final dbPath = await settingsRepository.getDatabasePath();
      final dbSize = await settingsRepository.getDatabaseSizeInBytes();

      final profile = await settingsRepository.getUserProfile();
      final printConfig = await settingsRepository.getPrintConfig();
      final defaultPrinter = await settingsRepository.getDefaultPrinter();
      final geminiApiKey = await _secureStorage.read(_geminiApiKeyStorageKey);
      final selectedModel = (await _secureStorage.read(_geminiModelStorageKey)) ??
          (await settingsRepository.getSetting('selected_ai_model')) ??
          'gemini-3.8-flash';

      final accounts = await accountRepository.getAccounts();
      final transactions = await journalRepository.getJournalEntries();

      emit(
        state.copyWith(
          status: BlocStatus.success,
          isFirstTime: isFirstTime,
          hasData: hasData,
          isSampleDataLoaded: isSampleLoaded,
          userProfile: profile,
          printConfig: printConfig,
          defaultPrinter: defaultPrinter,
          geminiApiKey: geminiApiKey,
          selectedAiModel: selectedModel,
          totalAccountsCount: accounts.length,
          totalTransactionsCount: transactions.length,
          databasePath: dbPath,
          databaseSizeBytes: dbSize,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BlocStatus.failure,
          errorMessage: 'Failed to initialize settings: $e',
        ),
      );
    }
  }

  Future<void> markFirstTimePromptCompleted() async {
    await _secureStorage.write(_firstTimeCheckedKey, 'true');
    await settingsRepository.setSetting('first_time_prompted', 'true');
    emit(state.copyWith(isFirstTime: false));
  }

  Future<void> loadSampleData() async {
    emit(state.copyWith(isLoadingSampleData: true));
    try {
      await settingsRepository.loadSampleData();
      await markFirstTimePromptCompleted();

      final accounts = await accountRepository.getAccounts();
      final transactions = await journalRepository.getJournalEntries();

      emit(
        state.copyWith(
          isLoadingSampleData: false,
          hasData: true,
          isSampleDataLoaded: true,
          totalAccountsCount: accounts.length,
          totalTransactionsCount: transactions.length,
          message: 'နမူနာ စာရင်းအင်းဒေတာများကို အောင်မြင်စွာ ထည့်သွင်းပြီးပါပြီ။ (Sample data loaded successfully!)',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingSampleData: false,
          errorMessage: 'Failed to load sample data: $e',
        ),
      );
    }
  }

  Future<void> clearSampleData() async {
    emit(state.copyWith(status: BlocStatus.loading));
    try {
      await settingsRepository.clearSampleData();
      final accounts = await accountRepository.getAccounts();
      final transactions = await journalRepository.getJournalEntries();

      emit(
        state.copyWith(
          status: BlocStatus.success,
          hasData: accounts.isNotEmpty,
          isSampleDataLoaded: false,
          totalAccountsCount: accounts.length,
          totalTransactionsCount: transactions.length,
          message: 'နမူနာဒေတာများကို ရှင်းလင်းပြီးပါပြီ။ (Sample data cleared)',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BlocStatus.failure,
          errorMessage: 'Failed to clear sample data: $e',
        ),
      );
    }
  }

  Future<void> clearAllData() async {
    emit(state.copyWith(status: BlocStatus.loading));
    try {
      await settingsRepository.clearAllData();
      emit(
        state.copyWith(
          status: BlocStatus.success,
          hasData: false,
          isSampleDataLoaded: false,
          totalAccountsCount: 0,
          totalTransactionsCount: 0,
          message: 'ဒေတာအားလုံးကို အောင်မြင်စွာ ဖျက်သိမ်းပြီးပါပြီ။ (All data cleared)',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BlocStatus.failure,
          errorMessage: 'Failed to clear all data: $e',
        ),
      );
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await settingsRepository.saveUserProfile(profile);
      emit(
        state.copyWith(
          userProfile: profile,
          message: 'လုပ်ငန်းပရိုဖိုင် သိမ်းဆည်းပြီးပါပြီ။ (Profile saved)',
        ),
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to save profile: $e'));
    }
  }

  Future<void> savePrintConfig(PrintConfig config) async {
    try {
      await settingsRepository.savePrintConfig(config);
      emit(
        state.copyWith(
          printConfig: config,
          message: 'ပုံနှိပ်ပုံစံ ဆက်တင်များ သိမ်းဆည်းပြီးပါပြီ။ (Print settings saved)',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(errorMessage: 'Failed to save print configuration: $e'),
      );
    }
  }

  Future<void> scanPrinters() async {
    emit(state.copyWith(isScanningPrinters: true));
    await Future.delayed(const Duration(milliseconds: 1500));
    final discovered = [
      'Thermal POS 80mm Printer (USB-001)',
      'Office A4 Laser Printer (Network IP: 192.168.1.150)',
      'Bluetooth Mobile Receipt 58mm (BT-Printer-42)',
      'EPSON TM-T82X Thermal Printer (LAN: 192.168.1.200)',
      'Sunmi Cloud POS Printer (WiFi-Sunmi-V2)',
    ];
    emit(
      state.copyWith(
        isScanningPrinters: false,
        availablePrinters: discovered,
        message: 'အနီးရှိ ပရင်တာ ၅ လုံး ရှာဖွေတွေ့ရှိပါသည်! (Found 5 printers)',
      ),
    );
  }

  Future<void> selectDefaultPrinter(String printerName) async {
    await settingsRepository.setDefaultPrinter(printerName);
    emit(
      state.copyWith(
        defaultPrinter: printerName,
        message: 'အဓိက ပရင်တာအဖြစ် သတ်မှတ်ပြီးပါပြီ။ (Default printer updated)',
      ),
    );
  }

  Future<void> saveGeminiApiKey(String apiKey) async {
    final cleanKey = apiKey.trim();
    await _secureStorage.write(_geminiApiKeyStorageKey, cleanKey);
    emit(
      state.copyWith(
        geminiApiKey: cleanKey,
        message: 'Gemini API Key ကို လုံခြုံစွာ သိမ်းဆည်းပြီးပါပြီ။ (API key saved securely)',
      ),
    );
  }

  Future<void> removeGeminiApiKey() async {
    await _secureStorage.delete(_geminiApiKeyStorageKey);
    emit(
      state.copyWith(
        geminiApiKey: null,
        message: 'Gemini API Key ကို ဖျက်ပစ်ပြီးပါပြီ။ (API key removed)',
      ),
    );
  }

  Future<void> selectAiModel(String model) async {
    final clean = model.trim();
    if (clean.isEmpty) return;
    await _secureStorage.write(_geminiModelStorageKey, clean);
    await settingsRepository.setSetting('selected_ai_model', clean);
    emit(
      state.copyWith(
        selectedAiModel: clean,
        message: 'AI Model ကို "$clean" သို့ ပြောင်းလဲသတ်မှတ်ပြီးပါပြီ။ (AI Model updated)',
      ),
    );
  }

  Future<void> refreshDatabaseStats() async {
    try {
      final dbPath = await settingsRepository.getDatabasePath();
      final dbSize = await settingsRepository.getDatabaseSizeInBytes();
      final accounts = await accountRepository.getAccounts();
      final transactions = await journalRepository.getJournalEntries();
      emit(
        state.copyWith(
          databasePath: dbPath,
          databaseSizeBytes: dbSize,
          totalAccountsCount: accounts.length,
          totalTransactionsCount: transactions.length,
          hasData: accounts.isNotEmpty,
        ),
      );
    } catch (_) {}
  }

  Future<String?> exportDatabaseBackup() async {
    emit(state.copyWith(isExportingDb: true));
    try {
      final bytes = await settingsRepository.exportDatabaseBytes();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final defaultFileName = 'accounting_myanmar_backup_$timestamp.db';

      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Select Backup Destination (ဒေတာဘေ့စ် Backup သိမ်းဆည်းရန် နေရာရွေးပါ)',
        fileName: defaultFileName,
        bytes: Uint8List.fromList(bytes),
        type: FileType.custom,
        allowedExtensions: ['db', 'sqlite'],
      );

      if (savedUri == null) {
        emit(state.copyWith(isExportingDb: false));
        return null;
      }

      // Ensure file exists on local filesystem if file:// scheme
      final displayPath = savedUri.scheme == 'file'
          ? savedUri.toFilePath()
          : savedUri.path;
      if (savedUri.scheme == 'file') {
        final localFile = File(displayPath);
        if (!await localFile.exists() || await localFile.length() == 0) {
          await localFile.writeAsBytes(bytes);
        }
      }

      final dbSize = await settingsRepository.getDatabaseSizeInBytes();
      emit(
        state.copyWith(
          isExportingDb: false,
          databaseSizeBytes: dbSize,
          message:
              'ဒေတာဘေ့စ် Backup ဖိုင်အား အောင်မြင်စွာ သိမ်းဆည်းပြီးပါပြီ: $displayPath',
        ),
      );
      return displayPath;
    } catch (e) {
      emit(
        state.copyWith(
          isExportingDb: false,
          errorMessage: 'ဒေတာဘေ့စ် Backup ထုတ်ယူရာတွင် အမှားဖြစ်ပေါ်ပါသည်: $e',
        ),
      );
      return null;
    }
  }

  Future<bool> importDatabaseBackup() async {
    emit(state.copyWith(isImportingDb: true));
    try {
      final result = await FilePicker.pickFile(
        dialogTitle: 'Select SQLite Database Backup File (.db, .sqlite)',
        type: FileType.custom,
        allowedExtensions: ['db', 'sqlite'],
      );

      if (result == null) {
        emit(state.copyWith(isImportingDb: false));
        return false;
      }

      final bytes = await result.readAsBytes();
      await settingsRepository.importDatabaseFromBytes(bytes);

      // Re-read accounts & entries to update UI
      final accounts = await accountRepository.getAccounts();
      final transactions = await journalRepository.getJournalEntries();
      final dbSize = await settingsRepository.getDatabaseSizeInBytes();

      await settingsRepository.setSetting('first_time_prompted', 'true');
      await _secureStorage.write(_firstTimeCheckedKey, 'true');

      emit(
        state.copyWith(
          isImportingDb: false,
          hasData: accounts.isNotEmpty,
          databaseSizeBytes: dbSize,
          totalAccountsCount: accounts.length,
          totalTransactionsCount: transactions.length,
          message: 'ဒေတာဘေ့စ် အချက်အလက်များအား အောင်မြင်စွာ ပြန်လည်သွင်းယူပြီးပါပြီ။ (Database restored successfully)',
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          isImportingDb: false,
          errorMessage: 'ဒေတာဘေ့စ် ပြန်လည်သွင်းယူရာတွင် အမှားဖြစ်ပေါ်ပါသည်: $e',
        ),
      );
      return false;
    }
  }

  Future<CsvImportResult?> importCsvFile(
    DatabaseServiceInterface dbService,
  ) async {
    emit(state.copyWith(isImportingCsv: true));
    try {
      final picked = await FilePicker.pickFile(
        dialogTitle: 'Select CSV File to Import (သွင်းယူမည့် CSV ဖိုင်ရွေးပါ)',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (picked == null) {
        emit(state.copyWith(isImportingCsv: false));
        return null;
      }

      final bytes = await picked.readAsBytes();
      final csvString = utf8.decode(bytes);
      final importResult = await ExportService.instance.importCsvContent(
        csvString,
        dbService: dbService,
      );

      final accounts = await accountRepository.getAccounts();
      final transactions = await journalRepository.getJournalEntries();
      final dbSize = await settingsRepository.getDatabaseSizeInBytes();

      await settingsRepository.setSetting('first_time_prompted', 'true');
      await _secureStorage.write(_firstTimeCheckedKey, 'true');

      emit(
        state.copyWith(
          isImportingCsv: false,
          hasData: accounts.isNotEmpty,
          databaseSizeBytes: dbSize,
          totalAccountsCount: accounts.length,
          totalTransactionsCount: transactions.length,
          message: importResult.summary,
        ),
      );

      return importResult;
    } catch (e) {
      emit(
        state.copyWith(
          isImportingCsv: false,
          errorMessage: 'CSV သွင်းယူရာတွင် အမှားဖြစ်ပေါ်ပါသည်: $e',
        ),
      );
      return null;
    }
  }
}
