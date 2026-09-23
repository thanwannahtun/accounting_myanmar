import 'package:equatable/equatable.dart';
import '../../core/bloc_utils/bloc_status.dart';
import '../../data/models/journal_entry.dart';

class JournalEntryState extends Equatable {
  final BlocStatus status;
  final List<JournalEntry> entries;
  final String? errorMessage;

  const JournalEntryState({
    this.status = BlocStatus.initial,
    this.entries = const [],
    this.errorMessage,
  });

  JournalEntryState copyWith({
    BlocStatus? status,
    List<JournalEntry>? entries,
    String? errorMessage,
  }) {
    return JournalEntryState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, entries, errorMessage];
}
