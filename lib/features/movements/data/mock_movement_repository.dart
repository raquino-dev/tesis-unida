import '../../../core/errors/app_failure.dart';
import '../../../mock/mock_data.dart';
import '../../accounts/domain/account_entity.dart';
import '../../accounts/domain/account_repository.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/domain/category_repository.dart';
import '../domain/movement_entity.dart';
import '../domain/movement_repository.dart';
import 'models/movement_model.dart';

class MockMovementRepository implements MovementRepository {
  final CategoryRepository _categoryRepository;
  final AccountRepository _accountRepository;
  List<MovementModel>? _cache;
  int _sequence = 100;

  MockMovementRepository(this._categoryRepository, this._accountRepository);

  Future<List<MovementModel>> _load() async {
    _cache ??= MockData.movements(
      DateTime.now(),
    ).map(MovementModel.fromMock).toList();
    return _cache!;
  }

  Future<List<CategoryEntity>> _categoriesFor(
    List<String> ids,
    List<CategoryEntity> all,
  ) async {
    final matched = all.where((c) => ids.contains(c.id)).toList();
    return matched.isEmpty ? [all.last] : matched;
  }

  Future<AccountEntity> _accountFor(String id, List<AccountEntity> all) async {
    return all.firstWhere((a) => a.id == id, orElse: () => all.first);
  }

  Future<MovementEntity> _toEntity(
    MovementModel model,
    List<CategoryEntity> categories,
    List<AccountEntity> accounts,
  ) async {
    return model.toEntity(
      categories: await _categoriesFor(model.categoryIds, categories),
      account: await _accountFor(model.accountId, accounts),
    );
  }

  @override
  Future<List<MovementEntity>> getMovements() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final models = await _load();
    final categories = await _categoryRepository.getCategories();
    final accounts = await _accountRepository.getAccounts();
    final sorted = [...models]..sort((a, b) => b.date.compareTo(a.date));
    final result = <MovementEntity>[];
    for (final m in sorted) {
      result.add(await _toEntity(m, categories, accounts));
    }
    return result;
  }

  @override
  Future<MovementEntity> getMovementById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final models = await _load();
    final model = models.firstWhere(
      (m) => m.id == id,
      orElse: () => throw const AppFailure('Movimiento no encontrado.'),
    );
    final categories = await _categoryRepository.getCategories();
    final accounts = await _accountRepository.getAccounts();
    return _toEntity(model, categories, accounts);
  }

  @override
  Future<MovementEntity> addMovement(MovementEntity movement) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final models = await _load();
    final id = 'mov_${_sequence++}';
    final model = MovementModel(
      id: id,
      type: movement.type,
      amount: movement.amount,
      date: movement.date,
      categoryIds: movement.categories.map((c) => c.id).toList(),
      description: movement.description,
      accountId: movement.account.id,
      hasAttachment: movement.hasAttachment,
      attachmentType: movement.attachmentType,
      ocrStatus: movement.ocrStatus,
      attachmentPath: movement.attachmentPath,
      attachmentName: movement.attachmentName,
    );
    models.add(model);
    return model.toEntity(
      categories: movement.categories,
      account: movement.account,
    );
  }

  @override
  Future<MovementEntity> updateMovement(MovementEntity movement) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final models = await _load();
    final index = models.indexWhere((m) => m.id == movement.id);
    if (index == -1) throw const AppFailure('Movimiento no encontrado.');
    final updated = MovementModel(
      id: movement.id,
      type: movement.type,
      amount: movement.amount,
      date: movement.date,
      categoryIds: movement.categories.map((c) => c.id).toList(),
      description: movement.description,
      accountId: movement.account.id,
      hasAttachment: movement.hasAttachment,
      attachmentType: movement.attachmentType,
      ocrStatus: movement.ocrStatus,
      attachmentPath: movement.attachmentPath,
      attachmentName: movement.attachmentName,
    );
    models[index] = updated;
    return updated.toEntity(
      categories: movement.categories,
      account: movement.account,
    );
  }

  @override
  Future<void> deleteMovement(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final models = await _load();
    models.removeWhere((m) => m.id == id);
  }

  @override
  Future<MovementEntity> reprocessOcr(String id) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final models = await _load();
    final index = models.indexWhere((m) => m.id == id);
    if (index == -1) throw const AppFailure('Movimiento no encontrado.');
    final reprocessed = MovementModel(
      id: models[index].id,
      type: models[index].type,
      amount: models[index].amount,
      date: models[index].date,
      categoryIds: models[index].categoryIds,
      description: models[index].description,
      accountId: models[index].accountId,
      hasAttachment: models[index].hasAttachment,
      attachmentType: models[index].attachmentType,
      ocrStatus: OcrStatus.success,
      attachmentPath: models[index].attachmentPath,
      attachmentName: models[index].attachmentName,
    );
    models[index] = reprocessed;
    final categories = await _categoryRepository.getCategories();
    final accounts = await _accountRepository.getAccounts();
    return _toEntity(reprocessed, categories, accounts);
  }
}
