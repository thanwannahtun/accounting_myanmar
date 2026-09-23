import 'package:equatable/equatable.dart';
import '../../core/bloc_utils/bloc_status.dart';
import '../../data/models/account.dart';

class AccountState extends Equatable {
  final BlocStatus status;
  final List<Account> accounts;
  final String? errorMessage;

  const AccountState({
    this.status = BlocStatus.initial,
    this.accounts = const [],
    this.errorMessage,
  });

  AccountState copyWith({
    BlocStatus? status,
    List<Account>? accounts,
    String? errorMessage,
  }) {
    return AccountState(
      status: status ?? this.status,
      accounts: accounts ?? this.accounts,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, accounts, errorMessage];
}
