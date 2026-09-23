import 'package:equatable/equatable.dart';
import '../../core/bloc_utils/bloc_status.dart';
import '../../data/models/print_config.dart';
import '../../data/models/user_profile.dart';

class SettingsState extends Equatable {
  final BlocStatus status;
  final bool isFirstTime;
  final bool isSampleDataLoaded;
  final bool hasData;
  final bool isLoadingSampleData;
  final UserProfile userProfile;
  final PrintConfig printConfig;
  final String defaultPrinter;
  final List<String> availablePrinters;
  final bool isScanningPrinters;
  final String? geminiApiKey;
  final int totalAccountsCount;
  final int totalTransactionsCount;
  final String? message;
  final String? errorMessage;

  const SettingsState({
    this.status = BlocStatus.initial,
    this.isFirstTime = false,
    this.isSampleDataLoaded = false,
    this.hasData = false,
    this.isLoadingSampleData = false,
    this.userProfile = const UserProfile(),
    this.printConfig = const PrintConfig(),
    this.defaultPrinter = 'Thermal POS 80mm Printer (USB-001)',
    this.availablePrinters = const [
      'Thermal POS 80mm Printer (USB-001)',
      'Office A4 Laser Printer (Network IP: 192.168.1.150)',
      'Bluetooth Mobile Receipt 58mm (BT-Printer-42)',
    ],
    this.isScanningPrinters = false,
    this.geminiApiKey,
    this.totalAccountsCount = 0,
    this.totalTransactionsCount = 0,
    this.message,
    this.errorMessage,
  });

  SettingsState copyWith({
    BlocStatus? status,
    bool? isFirstTime,
    bool? isSampleDataLoaded,
    bool? hasData,
    bool? isLoadingSampleData,
    UserProfile? userProfile,
    PrintConfig? printConfig,
    String? defaultPrinter,
    List<String>? availablePrinters,
    bool? isScanningPrinters,
    String? geminiApiKey,
    int? totalAccountsCount,
    int? totalTransactionsCount,
    String? message,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      isFirstTime: isFirstTime ?? this.isFirstTime,
      isSampleDataLoaded: isSampleDataLoaded ?? this.isSampleDataLoaded,
      hasData: hasData ?? this.hasData,
      isLoadingSampleData: isLoadingSampleData ?? this.isLoadingSampleData,
      userProfile: userProfile ?? this.userProfile,
      printConfig: printConfig ?? this.printConfig,
      defaultPrinter: defaultPrinter ?? this.defaultPrinter,
      availablePrinters: availablePrinters ?? this.availablePrinters,
      isScanningPrinters: isScanningPrinters ?? this.isScanningPrinters,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      totalAccountsCount: totalAccountsCount ?? this.totalAccountsCount,
      totalTransactionsCount: totalTransactionsCount ?? this.totalTransactionsCount,
      message: message,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    isFirstTime,
    isSampleDataLoaded,
    hasData,
    isLoadingSampleData,
    userProfile,
    printConfig,
    defaultPrinter,
    availablePrinters,
    isScanningPrinters,
    geminiApiKey,
    totalAccountsCount,
    totalTransactionsCount,
    message,
    errorMessage,
  ];
}
