import '../../models/print_config.dart';
import '../../models/user_profile.dart';

abstract class SettingsRepositoryInterface {
  Future<bool> hasData();
  Future<bool> isSampleDataLoaded();
  Future<void> loadSampleData();
  Future<void> clearSampleData();
  Future<void> clearAllData();

  Future<UserProfile> getUserProfile();
  Future<void> saveUserProfile(UserProfile profile);

  Future<PrintConfig> getPrintConfig();
  Future<void> savePrintConfig(PrintConfig config);

  Future<String> getDefaultPrinter();
  Future<void> setDefaultPrinter(String printerName);
}
