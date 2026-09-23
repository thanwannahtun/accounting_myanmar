import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc_utils/bloc_status.dart';
import '../../core/secure_storage_service.dart';
import '../../data/models/print_config.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/account/account_repository_interface.dart';
import '../../data/repositories/journal/journal_entry_repository_interface.dart';
import '../../data/repositories/settings/settings_repository_interface.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepositoryInterface settingsRepository;
  final AccountRepositoryInterface accountRepository;
  final JournalEntryRepositoryInterface journalRepository;
  final SecureStorageService _secureStorage;

  static const String _geminiApiKeyStorageKey = 'gemini_api_key_secure_storage';
  static const String _firstTimeCheckedKey = 'has_prompted_first_time_load';

  SettingsCubit({
    required this.settingsRepository,
    required this.accountRepository,
    required this.journalRepository,
    SecureStorageService? secureStorage,
  })  : _secureStorage = secureStorage ?? SecureStorageService.instance,
        super(const SettingsState());

  Future<void> init() async {
    emit(state.copyWith(status: BlocStatus.loading));
    try {
      final hasData = await settingsRepository.hasData();
      final isSampleLoaded = await settingsRepository.isSampleDataLoaded();
      final hasPromptedFirstTime = (await _secureStorage.read(_firstTimeCheckedKey)) == 'true';
      final isFirstTime = !hasPromptedFirstTime && !hasData;

      final profile = await settingsRepository.getUserProfile();
      final printConfig = await settingsRepository.getPrintConfig();
      final defaultPrinter = await settingsRepository.getDefaultPrinter();
      final geminiApiKey = await _secureStorage.read(_geminiApiKeyStorageKey);

      final accounts = await accountRepository.getAccounts();
      final transactions = await journalRepository.getJournalEntries();

      emit(state.copyWith(
        status: BlocStatus.success,
        isFirstTime: isFirstTime,
        hasData: hasData,
        isSampleDataLoaded: isSampleLoaded,
        userProfile: profile,
        printConfig: printConfig,
        defaultPrinter: defaultPrinter,
        geminiApiKey: geminiApiKey,
        totalAccountsCount: accounts.length,
        totalTransactionsCount: transactions.length,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: 'Failed to initialize settings: $e',
      ));
    }
  }

  Future<void> markFirstTimePromptCompleted() async {
    await _secureStorage.write(_firstTimeCheckedKey, 'true');
    emit(state.copyWith(isFirstTime: false));
  }

  Future<void> loadSampleData() async {
    emit(state.copyWith(isLoadingSampleData: true));
    try {
      await settingsRepository.loadSampleData();
      await markFirstTimePromptCompleted();

      final accounts = await accountRepository.getAccounts();
      final transactions = await journalRepository.getJournalEntries();

      emit(state.copyWith(
        isLoadingSampleData: false,
        hasData: true,
        isSampleDataLoaded: true,
        totalAccountsCount: accounts.length,
        totalTransactionsCount: transactions.length,
        message: 'နမူနာ စာရင်းအင်းဒေတာများကို အောင်မြင်စွာ ထည့်သွင်းပြီးပါပြီ။ (Sample data loaded successfully!)',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingSampleData: false,
        errorMessage: 'Failed to load sample data: $e',
      ));
    }
  }

  Future<void> clearSampleData() async {
    emit(state.copyWith(status: BlocStatus.loading));
    try {
      await settingsRepository.clearSampleData();
      final accounts = await accountRepository.getAccounts();
      final transactions = await journalRepository.getJournalEntries();

      emit(state.copyWith(
        status: BlocStatus.success,
        hasData: accounts.isNotEmpty,
        isSampleDataLoaded: false,
        totalAccountsCount: accounts.length,
        totalTransactionsCount: transactions.length,
        message: 'နမူနာဒေတာများကို ရှင်းလင်းပြီးပါပြီ။ (Sample data cleared)',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: 'Failed to clear sample data: $e',
      ));
    }
  }

  Future<void> clearAllData() async {
    emit(state.copyWith(status: BlocStatus.loading));
    try {
      await settingsRepository.clearAllData();
      emit(state.copyWith(
        status: BlocStatus.success,
        hasData: false,
        isSampleDataLoaded: false,
        totalAccountsCount: 0,
        totalTransactionsCount: 0,
        message: 'ဒေတာအားလုံးကို အောင်မြင်စွာ ဖျက်သိမ်းပြီးပါပြီ။ (All data cleared)',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: 'Failed to clear all data: $e',
      ));
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      await settingsRepository.saveUserProfile(profile);
      emit(state.copyWith(
        userProfile: profile,
        message: 'လုပ်ငန်းပရိုဖိုင် သိမ်းဆည်းပြီးပါပြီ။ (Profile saved)',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to save profile: $e'));
    }
  }

  Future<void> savePrintConfig(PrintConfig config) async {
    try {
      await settingsRepository.savePrintConfig(config);
      emit(state.copyWith(
        printConfig: config,
        message: 'ပုံနှိပ်ပုံစံ ဆက်တင်များ သိမ်းဆည်းပြီးပါပြီ။ (Print settings saved)',
      ));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to save print configuration: $e'));
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
    emit(state.copyWith(
      isScanningPrinters: false,
      availablePrinters: discovered,
      message: 'အနီးရှိ ပရင်တာ ၅ လုံး ရှာဖွေတွေ့ရှိပါသည်! (Found 5 printers)',
    ));
  }

  Future<void> selectDefaultPrinter(String printerName) async {
    await settingsRepository.setDefaultPrinter(printerName);
    emit(state.copyWith(
      defaultPrinter: printerName,
      message: 'အဓိက ပရင်တာအဖြစ် သတ်မှတ်ပြီးပါပြီ။ (Default printer updated)',
    ));
  }

  Future<void> saveGeminiApiKey(String apiKey) async {
    final cleanKey = apiKey.trim();
    await _secureStorage.write(_geminiApiKeyStorageKey, cleanKey);
    emit(state.copyWith(
      geminiApiKey: cleanKey,
      message: 'Gemini API Key ကို လုံခြုံစွာ သိမ်းဆည်းပြီးပါပြီ။ (API key saved securely)',
    ));
  }

  Future<void> removeGeminiApiKey() async {
    await _secureStorage.delete(_geminiApiKeyStorageKey);
    emit(state.copyWith(
      geminiApiKey: null,
      message: 'Gemini API Key ကို ဖျက်ပစ်ပြီးပါပြီ။ (API key removed)',
    ));
  }
}
