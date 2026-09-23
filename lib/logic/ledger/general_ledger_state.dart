import 'package:equatable/equatable.dart';
import '../../core/bloc_utils/bloc_status.dart';
import '../../data/models/account.dart';
import '../../data/models/financial_report.dart';
import '../../data/services/export/export_service.dart';
import '../../data/services/print/print_service.dart';

class GeneralLedgerState extends Equatable {
  final BlocStatus status;
  final Account? selectedAccount;
  final List<LedgerEntry> entries;
  final double endingBalance;
  final ExportResult? lastExport;
  final FormattedPrintDocument? lastPrintDoc;
  final String? errorMessage;

  const GeneralLedgerState({
    this.status = BlocStatus.initial,
    this.selectedAccount,
    this.entries = const [],
    this.endingBalance = 0.0,
    this.lastExport,
    this.lastPrintDoc,
    this.errorMessage,
  });

  GeneralLedgerState copyWith({
    BlocStatus? status,
    Account? selectedAccount,
    List<LedgerEntry>? entries,
    double? endingBalance,
    ExportResult? lastExport,
    FormattedPrintDocument? lastPrintDoc,
    String? errorMessage,
  }) {
    return GeneralLedgerState(
      status: status ?? this.status,
      selectedAccount: selectedAccount ?? this.selectedAccount,
      entries: entries ?? this.entries,
      endingBalance: endingBalance ?? this.endingBalance,
      lastExport: lastExport ?? this.lastExport,
      lastPrintDoc: lastPrintDoc ?? this.lastPrintDoc,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedAccount,
    entries,
    endingBalance,
    lastExport,
    lastPrintDoc,
    errorMessage,
  ];
}
