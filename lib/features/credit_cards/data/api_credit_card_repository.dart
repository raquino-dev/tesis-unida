import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/offline/offline_models.dart';
import '../../../core/utils/uuid_v4.dart';
import '../../accounts/domain/account_entity.dart';
import '../../accounts/domain/account_repository.dart';
import '../domain/credit_card_entity.dart';
import '../domain/credit_card_repository.dart';

class ApiCreditCardRepository implements CreditCardRepository {
  final ApiClient _api;
  final AccountRepository _accounts;
  final Map<String, int> _versions = {};

  ApiCreditCardRepository(this._api, this._accounts);

  @override
  Future<List<CreditCardEntity>> getCreditCards() async {
    final response = (await _api.get('/tarjetas-credito')).object;
    final accounts = await _accounts.getAccounts();
    return (response['datos'] as List<dynamic>? ?? const [])
        .map((item) => _fromJson(item as Map<String, dynamic>, accounts))
        .toList();
  }

  @override
  Future<CreditCardEntity> createCreditCard(CreditCardEntity card) async {
    final id = uuidOrNew(card.id);
    final response = await _api.post(
      '/tarjetas-credito',
      body: {..._body(card), 'id': id},
      offline: OfflineMutation(
        entityType: 'tarjeta_credito',
        entityId: id,
        optimisticResponse: _json(card, id: id, version: 1),
        collectionPath: '/tarjetas-credito',
        collectionField: 'datos',
      ),
    );
    return _fromJson(response.object, [card.account]);
  }

  @override
  Future<CreditCardEntity> updateCreditCard(CreditCardEntity card) async {
    final version = await _versionFor(card.id);
    final response = await _api.patch(
      '/tarjetas-credito/${card.id}',
      body: _body(card),
      headers: {'If-Match': '"$version"'},
      offline: OfflineMutation(
        entityType: 'tarjeta_credito',
        entityId: card.id,
        optimisticResponse: _json(card, id: card.id, version: version + 1),
        collectionPath: '/tarjetas-credito',
        collectionField: 'datos',
      ),
    );
    return _fromJson(response.object, [card.account]);
  }

  @override
  Future<void> deleteCreditCard(String id) async {
    final version = await _versionFor(id);
    await _api.delete(
      '/tarjetas-credito/$id',
      headers: {'If-Match': '"$version"'},
      offline: OfflineMutation(
        entityType: 'tarjeta_credito',
        entityId: id,
        optimisticResponse: const <String, dynamic>{},
        collectionPath: '/tarjetas-credito',
        collectionField: 'datos',
      ),
    );
    _versions.remove(id);
  }

  Future<int> _versionFor(String id) async {
    if (_versions[id] case final version?) return version;
    final accounts = await _accounts.getAccounts();
    _fromJson((await _api.get('/tarjetas-credito/$id')).object, accounts);
    return _versions[id]!;
  }

  Map<String, dynamic> _body(CreditCardEntity card) => {
    'alias': card.alias,
    'cuentaPagoId': card.account.id,
    'diaCierre': card.closingDay,
    'diaVencimiento': card.dueDay,
    'limiteCredito': card.totalLimit.round(),
    'moneda': 'PYG',
    'color': card.color,
  };

  Map<String, dynamic> _json(
    CreditCardEntity card, {
    required String id,
    required int version,
  }) => {
    'id': id,
    'alias': card.alias,
    'cuentaPago': {
      'id': card.account.id,
      'nombre': card.account.name,
      'tipo': card.account.type.name,
    },
    'diaCierre': card.closingDay,
    'diaVencimiento': card.dueDay,
    'limiteCredito': card.totalLimit.round(),
    'saldoUtilizado': card.usedLimit.round(),
    'creditoDisponible': card.availableLimit.round(),
    'moneda': 'PYG',
    'color': card.color,
    'version': version,
  };

  CreditCardEntity _fromJson(
    Map<String, dynamic> json,
    List<AccountEntity> accounts,
  ) {
    final id = json['id'] as String;
    final accountId =
        (json['cuentaPago'] as Map<String, dynamic>)['id'] as String;
    final account = accounts.where((item) => item.id == accountId).firstOrNull;
    if (account == null) {
      throw const AppFailure(
        'La cuenta de pago de la tarjeta no está disponible.',
        code: 'missing_payment_account',
      );
    }
    final version = (json['version'] as num).toInt();
    _versions[id] = version;
    return CreditCardEntity(
      id: id,
      alias: json['alias'] as String,
      account: account,
      closingDay: (json['diaCierre'] as num).toInt(),
      dueDay: (json['diaVencimiento'] as num).toInt(),
      totalLimit: (json['limiteCredito'] as num).toDouble(),
      usedLimit: (json['saldoUtilizado'] as num).toDouble(),
      color: json['color'] as String? ?? '#6868A6',
      version: version,
    );
  }
}
