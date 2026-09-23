import 'package:equatable/equatable.dart';

class Account extends Equatable {
  final String id;
  final String code;
  final String name;
  final String type; // Asset, Liability, Equity, Revenue, Expense

  const Account({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
  });

  Account copyWith({
    String? id,
    String? code,
    String? name,
    String? type,
  }) {
    return Account(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'type': type,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
    );
  }

  @override
  List<Object?> get props => [id, code, name, type];
}
