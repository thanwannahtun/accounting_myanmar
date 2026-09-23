import 'package:equatable/equatable.dart';

class JournalEntryLine extends Equatable {
  final String id;
  final String journalEntryId;
  final String accountId;
  final double debit;
  final double credit;

  const JournalEntryLine({
    required this.id,
    required this.journalEntryId,
    required this.accountId,
    required this.debit,
    required this.credit,
  });

  JournalEntryLine copyWith({
    String? id,
    String? journalEntryId,
    String? accountId,
    double? debit,
    double? credit,
  }) {
    return JournalEntryLine(
      id: id ?? this.id,
      journalEntryId: journalEntryId ?? this.journalEntryId,
      accountId: accountId ?? this.accountId,
      debit: debit ?? this.debit,
      credit: credit ?? this.credit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'journal_entry_id': journalEntryId,
      'account_id': accountId,
      'debit': debit,
      'credit': credit,
    };
  }

  factory JournalEntryLine.fromMap(Map<String, dynamic> map) {
    return JournalEntryLine(
      id: map['id'] as String,
      journalEntryId: (map['journal_entry_id'] ?? '') as String,
      accountId: map['account_id'] as String,
      debit: (map['debit'] as num?)?.toDouble() ?? 0.0,
      credit: (map['credit'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [id, journalEntryId, accountId, debit, credit];
}
