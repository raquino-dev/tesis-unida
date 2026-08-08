import '../../accounts/domain/account_entity.dart';

/// Transferencia entre cuentas propias. No se contabiliza como ingreso ni
/// egreso real: es un movimiento de fondos entre cuentas, separado del
/// modelo de [MovementEntity] para no distorsionar reportes y dashboard.
class TransferEntity {
  final String id;
  final AccountEntity fromAccount;
  final AccountEntity toAccount;
  final double amount;
  final DateTime date;
  final String note;
  final bool isCancelled;
  final int version;

  const TransferEntity({
    required this.id,
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
    required this.date,
    this.note = '',
    this.isCancelled = false,
    this.version = 1,
  });

  TransferEntity copyWith({bool? isCancelled, int? version}) => TransferEntity(
    id: id,
    fromAccount: fromAccount,
    toAccount: toAccount,
    amount: amount,
    date: date,
    note: note,
    isCancelled: isCancelled ?? this.isCancelled,
    version: version ?? this.version,
  );
}
