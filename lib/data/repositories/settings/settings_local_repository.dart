import '../../../core/constants/seed_data.dart';
import '../../models/print_config.dart';
import '../../models/user_profile.dart';
import '../../services/database/database_service_interface.dart';
import 'settings_repository_interface.dart';

class SettingsLocalRepository implements SettingsRepositoryInterface {
  final DatabaseServiceInterface _databaseService;

  SettingsLocalRepository(this._databaseService);

  static const String _userProfileKey = 'user_profile_json';
  static const String _printConfigKey = 'print_config_json';
  static const String _defaultPrinterKey = 'default_printer_name';

  @override
  Future<bool> hasData() {
    return _databaseService.hasData();
  }

  @override
  Future<bool> isSampleDataLoaded() async {
    final flag = await _databaseService.getSetting('sample_data_loaded');
    return flag == 'true';
  }

  @override
  Future<void> loadSampleData() async {
    await _databaseService.seedInitialData(
      SeedData.initialAccounts,
      SeedData.initialTransactions,
    );
  }

  @override
  Future<void> clearSampleData() {
    return _databaseService.clearSampleData();
  }

  @override
  Future<void> clearAllData() {
    return _databaseService.clearAllData();
  }

  @override
  Future<UserProfile> getUserProfile() async {
    final jsonStr = await _databaseService.getSetting(_userProfileKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return const UserProfile();
    }
    try {
      return UserProfile.fromJson(jsonStr);
    } catch (_) {
      return const UserProfile();
    }
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) {
    return _databaseService.setSetting(_userProfileKey, profile.toJson());
  }

  @override
  Future<PrintConfig> getPrintConfig() async {
    final jsonStr = await _databaseService.getSetting(_printConfigKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return const PrintConfig();
    }
    try {
      return PrintConfig.fromJson(jsonStr);
    } catch (_) {
      return const PrintConfig();
    }
  }

  @override
  Future<void> savePrintConfig(PrintConfig config) {
    return _databaseService.setSetting(_printConfigKey, config.toJson());
  }

  @override
  Future<String> getDefaultPrinter() async {
    final val = await _databaseService.getSetting(_defaultPrinterKey);
    return val ?? 'Thermal POS Printer (USB-001)';
  }

  @override
  Future<void> setDefaultPrinter(String printerName) {
    return _databaseService.setSetting(_defaultPrinterKey, printerName);
  }
}
