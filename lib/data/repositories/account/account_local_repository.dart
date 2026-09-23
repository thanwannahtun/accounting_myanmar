import '../../models/account.dart';
import '../../services/database/database_service_interface.dart';
import 'account_repository_interface.dart';

class AccountLocalRepository implements AccountRepositoryInterface {
  final DatabaseServiceInterface _databaseService;

  AccountLocalRepository(this._databaseService);

  @override
  Future<List<Account>> getAccounts() {
    return _databaseService.getAllAccounts();
  }

  @override
  Future<Account?> getAccountById(String id) {
    return _databaseService.getAccountById(id);
  }

  @override
  Future<void> addAccount(Account account) {
    return _databaseService.insertAccount(account);
  }

  @override
  Future<void> updateAccount(Account account) {
    return _databaseService.updateAccount(account);
  }

  @override
  Future<void> deleteAccount(String id) {
    return _databaseService.deleteAccount(id);
  }
}
