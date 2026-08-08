import 'dart:math';

import '../../../core/network/api_client.dart';
import '../../accounts/domain/account_entity.dart';
import '../../accounts/domain/account_repository.dart';
import '../domain/transfer_entity.dart';
import '../domain/transfer_repository.dart';

class ApiTransferRepository implements TransferRepository {
  final ApiClient _api;
  final AccountRepository _accounts;
  final Map<String, int> _versions = {};

  ApiTransferRepository(this._api, this._accounts);

  @override
  Future<List<TransferEntity>> getTransfers() async {
    final response = (await _api.get('/transferencias')).object;
    final accounts = await _accounts.getAccounts();
    return (response['datos'] as List<dynamic>? ?? const [])
        .map((item) => _fromJson(item as Map<String, dynamic>, accounts))
        .toList();
  }

  @override
  Future<TransferEntity> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime date,
    String note = '',
  }) async {
    final response = await _api.post(
      '/transferencias',
      headers: {'Idempotency-Key': _idempotencyKey()},
      body: {
        'cuentaOrigenId': fromAccountId,
        'cuentaDestinoId': toAccountId,
        'monto': amount.round(),
        'fecha': _date(date),
        'descripcion': note.trim().isEmpty
            ? 'Transferencia interna'
            : note.trim(),
      },
    );
    return _fromJson(response.object, await _accounts.getAccounts());
  }

  @override
  Future<void> cancelTransfer(TransferEntity transfer) async {
    final version = _versions[transfer.id] ?? transfer.version;
    await _api.delete(
      '/transferencias/${transfer.id}',
      headers: {'If-Match': '"$version"'},
    );
    _versions.remove(transfer.id);
  }

  TransferEntity _fromJson(
    Map<String, dynamic> json,
    List<AccountEntity> accounts,
  ) {
    final originId =
        (json['cuentaOrigen'] as Map<String, dynamic>)['id'] as String;
    final destinationId =
        (json['cuentaDestino'] as Map<String, dynamic>)['id'] as String;
    final id = json['id'] as String;
    final version = (json['version'] as num).toInt();
    _versions[id] = version;
    return TransferEntity(
      id: id,
      fromAccount: accounts.firstWhere((item) => item.id == originId),
      toAccount: accounts.firstWhere((item) => item.id == destinationId),
      amount: (json['monto'] as num).toDouble(),
      date: DateTime.parse(json['fecha'] as String),
      note: json['descripcion'] as String? ?? '',
      isCancelled: json['estado'] == 'anulada',
      version: version,
    );
  }

  String _idempotencyKey() =>
      'flutter-${DateTime.now().microsecondsSinceEpoch}-'
      '${Random.secure().nextInt(1 << 32)}';

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
