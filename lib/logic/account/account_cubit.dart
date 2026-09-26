import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/bloc_utils/bloc_status.dart';
import '../../data/models/account.dart';
import '../../data/repositories/account/account_repository_interface.dart';
import 'account_state.dart';

class AccountCubit extends Cubit<AccountState> {
  final AccountRepositoryInterface _accountRepository;

  AccountCubit(this._accountRepository) : super(const AccountState());

  Future<void> loadAccounts() async {
    emit(state.copyWith(status: BlocStatus.loading));
    try {
      final accounts = await _accountRepository.getAccounts();
      emit(state.copyWith(
        status: BlocStatus.success,
        accounts: accounts,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> addAccount({
    required String code,
    required String name,
    required String type,
  }) async {
    try {
      final newAccount = Account(
        id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
        code: code.trim(),
        name: name.trim(),
        type: type.trim(),
      );
      await _accountRepository.addAccount(newAccount);
      await loadAccounts();
    } catch (e) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: 'Failed to add account: $e',
      ));
    }
  }

  Future<void> updateAccount(Account account) async {
    try {
      await _accountRepository.updateAccount(account);
      await loadAccounts();
    } catch (e) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: 'Failed to update account: $e',
      ));
    }
  }

  Future<void> deleteAccount(String id) async {
    try {
      await _accountRepository.deleteAccount(id);
      await loadAccounts();
    } catch (e) {
      emit(state.copyWith(
        status: BlocStatus.failure,
        errorMessage: 'Failed to delete account: $e',
      ));
    }
  }
}
