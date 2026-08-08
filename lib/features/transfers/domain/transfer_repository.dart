import 'transfer_entity.dart';

abstract class TransferRepository {
  Future<List<TransferEntity>> getTransfers();

  Future<TransferEntity> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime date,
    String note = '',
  });

  Future<void> cancelTransfer(TransferEntity transfer);
}
