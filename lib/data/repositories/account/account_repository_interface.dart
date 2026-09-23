import '../../models/account.dart';

abstract class AccountRepositoryInterface {
  Future<List<Account>> getAccounts();
  Future<Account?> getAccountById(String id);
  Future<void> addAccount(Account account);
  Future<void> updateAccount(Account account);
  Future<void> deleteAccount(String id);
}
