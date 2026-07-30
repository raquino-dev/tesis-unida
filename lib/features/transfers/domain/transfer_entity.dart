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

  const TransferEntity({
    required this.id,
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
    required this.date,
    this.note = '',
  });
}
