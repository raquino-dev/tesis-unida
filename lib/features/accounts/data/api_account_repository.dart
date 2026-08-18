import '../../../core/network/api_client.dart';
import '../../../core/offline/offline_models.dart';
import '../../../core/utils/uuid_v4.dart';
import '../domain/account_entity.dart';
import '../domain/account_repository.dart';

class ApiAccountRepository implements AccountRepository {
  final ApiClient _api;
  final Map<String, int> _versions = {};

  ApiAccountRepository(this._api);

  @override
  Future<List<AccountEntity>> getAccounts() async {
    final data = (await _api.get('/cuentas')).object;
    final items = (data['elementos'] as List<dynamic>? ?? const []);
    return items.map((item) => _fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<AccountEntity> createAccount(AccountEntity account) async {
    final id = uuidOrNew(account.id);
    final optimistic = _json(account, id: id, version: 1);
    final response = await _api.post(
      '/cuentas',
      body: {..._body(account), 'id': id},
      offline: OfflineMutation(
        entityType: 'cuenta',
        entityId: id,
        optimisticResponse: optimistic,
        collectionPath: '/cuentas',
      ),
    );
    return _fromJson(response.object);
  }

  @override
  Future<AccountEntity> updateAccount(AccountEntity account) async {
    final version = await _versionFor(account.id);
    final response = await _api.patch(
      '/cuentas/${account.id}',
      body: _body(account),
      headers: {'If-Match': '"$version"'},
      offline: OfflineMutation(
        entityType: 'cuenta',
        entityId: account.id,
        optimisticResponse: _json(account, id: account.id, version: version + 1),
        collectionPath: '/cuentas',
      ),
    );
    return _fromJson(response.object);
  }

  @override
  Future<void> deleteAccount(String id) async {
    final version = await _versionFor(id);
    await _api.delete(
      '/cuentas/$id',
      headers: {'If-Match': '"$version"'},
      offline: OfflineMutation(
        entityType: 'cuenta',
        entityId: id,
        optimisticResponse: const <String, dynamic>{},
        collectionPath: '/cuentas',
      ),
    );
    _versions.remove(id);
  }

  Future<int> _versionFor(String id) async {
    final cached = _versions[id];
    if (cached != null) return cached;
    _fromJson((await _api.get('/cuentas/$id')).object);
    return _versions[id]!;
  }

  Map<String, dynamic> _body(AccountEntity account) => {
    'nombre': account.name,
    'tipo': _typeToApi(account.type),
    'saldoInicial': account.initialBalance.round(),
    'moneda': 'PYG',
    'icono': account.icon.codePoint.toRadixString(16),
    'incluidaEnTotal': account.isActive,
  };

  Map<String, dynamic> _json(
    AccountEntity account, {
    required String id,
    required int version,
  }) => {
    'id': id,
    'nombre': account.name,
    'tipo': _typeToApi(account.type),
    'saldoInicial': account.initialBalance.round(),
    'saldoActual': account.initialBalance.round(),
    'moneda': 'PYG',
    'icono': account.icon.codePoint.toRadixString(16),
    'incluidaEnTotal': account.isActive,
    'version': version,
  };

  AccountEntity _fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    _versions[id] = (json['version'] as num).toInt();
    final type = _typeFromApi(json['tipo'] as String);
    return AccountEntity(
      id: id,
      name: json['nombre'] as String,
      type: type,
      icon: type.defaultIcon,
      initialBalance: (json['saldoActual'] as num).toDouble(),
      isActive: json['incluidaEnTotal'] as bool? ?? true,
      inUse: false,
    );
  }

  String _typeToApi(AccountType type) {
    switch (type) {
      case AccountType.cash:
        return 'efectivo';
      case AccountType.checkingAccount:
      case AccountType.bankAccount:
        return 'cuenta-corriente';
      case AccountType.savingsAccount:
        return 'cuenta-ahorro';
      case AccountType.debitCard:
        return 'tarjeta-debito';
      case AccountType.digitalWallet:
        return 'billetera-digital';
      case AccountType.creditCard:
      case AccountType.other:
        return 'otra';
    }
  }

  AccountType _typeFromApi(String value) {
    switch (value) {
      case 'efectivo':
        return AccountType.cash;
      case 'cuenta-corriente':
        return AccountType.checkingAccount;
      case 'cuenta-ahorro':
        return AccountType.savingsAccount;
      case 'tarjeta-debito':
        return AccountType.debitCard;
      case 'billetera-digital':
        return AccountType.digitalWallet;
      default:
        return AccountType.other;
    }
  }
}
