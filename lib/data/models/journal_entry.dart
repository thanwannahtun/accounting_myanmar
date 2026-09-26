import 'package:equatable/equatable.dart';
import 'journal_entry_line.dart';

class JournalEntry extends Equatable {
  final String id;
  final String date;
  final String description;
  final String? remark;
  final String status; // 'active', 'reversed', 'reversal'
  final String? linkedTransactionId;
  final List<JournalEntryLine> lines;
  final int? createdAt;

  const JournalEntry({
    required this.id,
    required this.date,
    required this.description,
    required this.lines,
    this.remark,
    this.status = 'active',
    this.linkedTransactionId,
    this.createdAt,
  });

  double get totalDebit =>
      lines.fold(0.0, (sum, line) => sum + line.debit);

  double get totalCredit =>
      lines.fold(0.0, (sum, line) => sum + line.credit);

  bool get isBalanced =>
      (totalDebit - totalCredit).abs() < 0.001 && totalDebit > 0;

  bool get isDraft => status == 'draft';
  bool get isPosted => status == 'posted' || status == 'active';
  bool get isReversed => status == 'reversed';
  bool get isReversal => status == 'reversal';
  bool get canReverse => isPosted;
  bool get canEdit => isDraft;
  bool get canDelete => isDraft;

  JournalEntry copyWith({
    String? id,
    String? date,
    String? description,
    String? remark,
    String? status,
    String? linkedTransactionId,
    List<JournalEntryLine>? lines,
    int? createdAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      description: description ?? this.description,
      remark: remark ?? this.remark,
      status: status ?? this.status,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
      lines: lines ?? this.lines,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'description': description,
      'remark': remark,
      'status': status,
      'linked_transaction_id': linkedTransactionId,
      'created_at': createdAt ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory JournalEntry.fromMap(
    Map<String, dynamic> map, [
    List<JournalEntryLine> lines = const [],
  ]) {
    return JournalEntry(
      id: map['id'] as String,
      date: map['date'] as String,
      description: map['description'] as String,
      remark: map['remark'] as String?,
      status: (map['status'] as String?) ?? 'active',
      linkedTransactionId: map['linked_transaction_id'] as String?,
      lines: lines,
      createdAt: map['created_at'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        description,
        remark,
        status,
        linkedTransactionId,
        lines,
        createdAt,
      ];
}
