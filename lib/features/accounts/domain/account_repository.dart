import 'account_entity.dart';

abstract class AccountRepository {
  Future<List<AccountEntity>> getAccounts();
  Future<AccountEntity> createAccount(AccountEntity account);
  Future<AccountEntity> updateAccount(AccountEntity account);
  Future<void> deleteAccount(String id);
}
