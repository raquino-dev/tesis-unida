import '../../../core/errors/app_failure.dart';
import '../../accounts/domain/account_entity.dart';
import '../../accounts/domain/account_repository.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/domain/category_repository.dart';
import '../../movements/domain/movement_entity.dart';
import '../domain/recurring_movement_entity.dart';
import '../domain/recurring_movement_repository.dart';

class MockRecurringMovementRepository implements RecurringMovementRepository {
  final CategoryRepository _categoryRepository;
  final AccountRepository _accountRepository;
  List<RecurringMovementEntity>? _cache;
  int _sequence = 100;

  MockRecurringMovementRepository(
    this._categoryRepository,
    this._accountRepository,
  );

  Future<List<RecurringMovementEntity>> _load() async {
    if (_cache != null) return _cache!;
    final categories = await _categoryRepository.getCategories();
    final accounts = await _accountRepository.getAccounts();

    CategoryEntity categoryByName(String name) => categories.firstWhere(
      (c) => c.name == name,
      orElse: () => categories.first,
    );
    AccountEntity accountById(String id) =>
        accounts.firstWhere((a) => a.id == id, orElse: () => accounts.first);

    final now = DateTime.now();
    _cache = [
      RecurringMovementEntity(
        id: 'rec_suscripcion',
        type: MovementType.expense,
        amount: 55000,
        categories: [categoryByName('Suscripciones')],
        account: accountById('acc_credito_itau'),
        description: 'Suscripción streaming',
        startDate: now.subtract(const Duration(days: 60)),
        frequency: RecurrenceFrequency.monthly,
        nextExecutionDate: now.add(const Duration(days: 2)),
      ),
      RecurringMovementEntity(
        id: 'rec_internet',
        type: MovementType.expense,
        amount: 180000,
        categories: [categoryByName('Servicios')],
        account: accountById('acc_debito_continental'),
        description: 'Internet',
        startDate: now.subtract(const Duration(days: 90)),
        frequency: RecurrenceFrequency.monthly,
        nextExecutionDate: now.add(const Duration(days: 5)),
      ),
      RecurringMovementEntity(
        id: 'rec_universidad',
        type: MovementType.expense,
        amount: 650000,
        categories: [categoryByName('Educación')],
        account: accountById('acc_billetera_tigo'),
        description: 'Universidad',
        startDate: now.subtract(const Duration(days: 120)),
        endDate: now.add(const Duration(days: 240)),
        frequency: RecurrenceFrequency.monthly,
        nextExecutionDate: now.add(const Duration(days: 12)),
      ),
    ];
    return _cache!;
  }

  @override
  Future<List<RecurringMovementEntity>> getRecurringMovements() async {
    await Future.delayed(const Duration(milliseconds: 450));
    final recurring = await _load();
    final sorted = [...recurring]
      ..sort((a, b) => a.nextExecutionDate.compareTo(b.nextExecutionDate));
    return List.unmodifiable(sorted);
  }

  @override
  Future<RecurringMovementEntity> createRecurringMovement(
    RecurringMovementEntity recurring,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final all = await _load();
    final created = RecurringMovementEntity(
      id: 'rec_${_sequence++}',
      type: recurring.type,
      amount: recurring.amount,
      categories: recurring.categories,
      account: recurring.account,
      description: recurring.description,
      startDate: recurring.startDate,
      endDate: recurring.endDate,
      frequency: recurring.frequency,
      totalOccurrences: recurring.totalOccurrences,
      nextExecutionDate: recurring.startDate,
      status: RecurringStatus.active,
    );
    all.add(created);
    return created;
  }

  @override
  Future<RecurringMovementEntity> updateRecurringMovement(
    RecurringMovementEntity recurring,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final all = await _load();
    final index = all.indexWhere((r) => r.id == recurring.id);
    if (index == -1) {
      throw const AppFailure('Movimiento recurrente no encontrado.');
    }
    all[index] = recurring;
    return recurring;
  }

  @override
  Future<void> deleteRecurringMovement(String id) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final all = await _load();
    all.removeWhere((r) => r.id == id);
  }
}
