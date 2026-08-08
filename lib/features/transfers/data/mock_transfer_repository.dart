import '../../../core/errors/app_failure.dart';
import '../../accounts/domain/account_repository.dart';
import '../domain/transfer_entity.dart';
import '../domain/transfer_repository.dart';

class MockTransferRepository implements TransferRepository {
  final AccountRepository _accountRepository;
  final List<TransferEntity> _transfers = [];
  int _sequence = 100;

  MockTransferRepository(this._accountRepository);

  @override
  Future<List<TransferEntity>> getTransfers() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final sorted = [..._transfers]..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(sorted);
  }

  @override
  Future<TransferEntity> createTransfer({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
    required DateTime date,
    String note = '',
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (fromAccountId == toAccountId) {
      throw const AppFailure(
        'No podés transferir dinero a la misma cuenta.',
        code: 'same_account',
      );
    }
    if (amount <= 0) {
      throw const AppFailure(
        'Ingresá un monto válido.',
        code: 'invalid_amount',
      );
    }

    final accounts = await _accountRepository.getAccounts();
    final fromAccount = accounts.firstWhere(
      (a) => a.id == fromAccountId,
      orElse: () => throw const AppFailure('Cuenta de origen no encontrada.'),
    );
    final toAccount = accounts.firstWhere(
      (a) => a.id == toAccountId,
      orElse: () => throw const AppFailure('Cuenta de destino no encontrada.'),
    );

    if (fromAccount.initialBalance < amount) {
      throw const AppFailure(
        'Saldo insuficiente en la cuenta de origen.',
        code: 'insufficient_balance',
      );
    }

    await _accountRepository.updateAccount(
      fromAccount.copyWith(initialBalance: fromAccount.initialBalance - amount),
    );
    await _accountRepository.updateAccount(
      toAccount.copyWith(initialBalance: toAccount.initialBalance + amount),
    );

    final transfer = TransferEntity(
      id: 'trf_${_sequence++}',
      fromAccount: fromAccount,
      toAccount: toAccount,
      amount: amount,
      date: date,
      note: note,
    );
    _transfers.add(transfer);
    return transfer;
  }

  @override
  Future<void> cancelTransfer(TransferEntity transfer) async {
    final index = _transfers.indexWhere((item) => item.id == transfer.id);
    if (index == -1) throw const AppFailure('Transferencia no encontrada.');
    if (_transfers[index].isCancelled) return;
    await _accountRepository.updateAccount(
      transfer.fromAccount.copyWith(
        initialBalance: transfer.fromAccount.initialBalance + transfer.amount,
      ),
    );
    await _accountRepository.updateAccount(
      transfer.toAccount.copyWith(
        initialBalance: transfer.toAccount.initialBalance - transfer.amount,
      ),
    );
    _transfers[index] = transfer.copyWith(
      isCancelled: true,
      version: transfer.version + 1,
    );
  }
}
