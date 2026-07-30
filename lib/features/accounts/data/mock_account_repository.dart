import '../../../core/errors/app_failure.dart';
import '../../../mock/mock_data.dart';
import '../domain/account_entity.dart';
import '../domain/account_repository.dart';

AccountType _typeFromString(String value) {
  return AccountType.values.firstWhere(
    (t) => t.name == value,
    orElse: () => AccountType.other,
  );
}

CardBrand _brandFromString(String value) {
  return CardBrand.values.firstWhere(
    (b) => b.name == value,
    orElse: () => CardBrand.none,
  );
}

class MockAccountRepository implements AccountRepository {
  final List<AccountEntity> _accounts = MockData.accounts
      .map(
        (a) => AccountEntity(
          id: a['id'] as String,
          name: a['name'] as String,
          type: _typeFromString(a['type'] as String),
          icon: a['icon'],
          brand: _brandFromString(a['brand'] as String),
          initialBalance: a['initialBalance'] as double,
          isActive: a['isActive'] as bool,
          inUse: a['inUse'] as bool,
        ),
      )
      .toList();

  @override
  Future<List<AccountEntity>> getAccounts() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_accounts);
  }

  @override
  Future<AccountEntity> createAccount(AccountEntity account) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _accounts.add(account);
    return account;
  }

  @override
  Future<AccountEntity> updateAccount(AccountEntity account) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _accounts.indexWhere((a) => a.id == account.id);
    if (index == -1) throw const AppFailure('Cuenta no encontrada.');
    _accounts[index] = account;
    return account;
  }

  @override
  Future<void> deleteAccount(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final account = _accounts.firstWhere(
      (a) => a.id == id,
      orElse: () => throw const AppFailure('Cuenta no encontrada.'),
    );
    if (account.inUse) {
      throw const AppFailure(
        'Esta cuenta está en uso y no puede eliminarse.',
        code: 'account_in_use',
      );
    }
    _accounts.removeWhere((a) => a.id == id);
  }
}
