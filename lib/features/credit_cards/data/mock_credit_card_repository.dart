import '../../../core/errors/app_failure.dart';
import '../../../mock/mock_data.dart';
import '../../accounts/domain/account_repository.dart';
import '../domain/credit_card_entity.dart';
import '../domain/credit_card_repository.dart';

class MockCreditCardRepository implements CreditCardRepository {
  final AccountRepository _accountRepository;
  List<CreditCardEntity>? _cache;
  int _sequence = 100;

  MockCreditCardRepository(this._accountRepository);

  Future<List<CreditCardEntity>> _load() async {
    if (_cache != null) return _cache!;
    final accounts = await _accountRepository.getAccounts();
    _cache = MockData.creditCards.map((c) {
      final account = accounts.firstWhere(
        (a) => a.id == c['accountId'],
        orElse: () => accounts.first,
      );
      return CreditCardEntity(
        id: c['id'] as String,
        alias: c['alias'] as String,
        account: account,
        closingDay: c['closingDay'] as int,
        dueDay: c['dueDay'] as int,
        totalLimit: c['totalLimit'] as double,
        usedLimit: c['usedLimit'] as double,
      );
    }).toList();
    return _cache!;
  }

  @override
  Future<List<CreditCardEntity>> getCreditCards() async {
    await Future.delayed(const Duration(milliseconds: 450));
    return List.unmodifiable(await _load());
  }

  @override
  Future<CreditCardEntity> createCreditCard(CreditCardEntity card) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final cards = await _load();
    final created = CreditCardEntity(
      id: 'cc_${_sequence++}',
      alias: card.alias,
      account: card.account,
      closingDay: card.closingDay,
      dueDay: card.dueDay,
      totalLimit: card.totalLimit,
      usedLimit: card.usedLimit,
    );
    cards.add(created);
    return created;
  }

  @override
  Future<CreditCardEntity> updateCreditCard(CreditCardEntity card) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final cards = await _load();
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index == -1) throw const AppFailure('Tarjeta no encontrada.');
    cards[index] = card;
    return card;
  }

  @override
  Future<void> deleteCreditCard(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final cards = await _load();
    cards.removeWhere((c) => c.id == id);
  }
}
