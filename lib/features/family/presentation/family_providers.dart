import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/utils/view_state.dart';
import '../../accounts/presentation/account_providers.dart';
import '../data/api_family_repository.dart';
import '../data/mock_family_repository.dart';
import '../domain/family_entity.dart';
import '../domain/family_repository.dart';

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  if (AppEnvironment.useApi) {
    return ApiFamilyRepository(ref.watch(apiClientProvider));
  }
  return MockFamilyRepository(ref.watch(accountRepositoryProvider));
});

class FamilyViewModel extends StateNotifier<ViewState<FamilyGroupEntity>> {
  final FamilyRepository _repository;
  FamilyViewModel(this._repository) : super(const ViewState.loading()) {
    load();
  }

  Future<void> load() async {
    state = const ViewState.loading();
    try {
      final group = await _repository.getFamilyGroup();
      state = group == null
          ? const ViewState.empty()
          : ViewState.success(group);
    } catch (e) {
      state = ViewState.error(
        appErrorMessage(e, fallback: 'No pudimos cargar el grupo familiar.'),
      );
    }
  }

  Future<String?> createGroup(String name) async {
    try {
      final group = await _repository.createFamilyGroup(name);
      state = ViewState.success(group);
      return null;
    } on AppFailure catch (e) {
      return e.message;
    }
  }

  Future<String?> addMember({
    required String name,
    required String email,
    required FamilyRole role,
  }) async {
    try {
      final group = await _repository.addMember(
        name: name,
        email: email,
        role: role,
      );
      state = ViewState.success(group);
      return null;
    } on AppFailure catch (e) {
      return e.message;
    }
  }

  Future<String?> updateMemberRole(String memberId, FamilyRole role) async {
    try {
      final group = await _repository.updateMemberRole(memberId, role);
      state = ViewState.success(group);
      return null;
    } on AppFailure catch (e) {
      return e.message;
    }
  }

  Future<String?> removeMember(String memberId) async {
    try {
      final group = await _repository.removeMember(memberId);
      state = ViewState.success(group);
      return null;
    } on AppFailure catch (e) {
      return e.message;
    }
  }

  Future<String?> addSharedAccount(String accountId) async {
    try {
      final group = await _repository.addSharedAccount(accountId);
      state = ViewState.success(group);
      return null;
    } on AppFailure catch (e) {
      return e.message;
    }
  }

  Future<String?> removeSharedAccount(String accountId) async {
    try {
      final group = await _repository.removeSharedAccount(accountId);
      state = ViewState.success(group);
      return null;
    } on AppFailure catch (e) {
      return e.message;
    }
  }
}

final familyViewModelProvider =
    StateNotifierProvider<FamilyViewModel, ViewState<FamilyGroupEntity>>((ref) {
      return FamilyViewModel(ref.watch(familyRepositoryProvider));
    });

class FamilyMovementListViewModel
    extends StateNotifier<ViewState<List<FamilyMovementEntity>>> {
  final FamilyRepository _repository;
  List<FamilyMovementEntity> _all = [];
  FamilyMovementFilters _filters = const FamilyMovementFilters();

  FamilyMovementFilters get filters => _filters;

  FamilyMovementListViewModel(this._repository)
    : super(const ViewState.loading()) {
    load();
  }

  Future<void> load() async {
    state = const ViewState.loading();
    try {
      _all = await _repository.getFamilyMovements();
      _emit();
    } catch (e) {
      state = ViewState.error(
        appErrorMessage(
          e,
          fallback: 'No pudimos cargar los movimientos familiares.',
        ),
      );
    }
  }

  void updateFilters(FamilyMovementFilters filters) {
    _filters = filters;
    _emit();
  }

  void _emit() {
    final results = _all.where(_filters.matches).toList();
    state = results.isEmpty
        ? const ViewState.empty()
        : ViewState.success(results);
  }

  Future<String?> addMovement(FamilyMovementEntity movement) async {
    try {
      await _repository.addFamilyMovement(movement);
      await load();
      return null;
    } on AppFailure catch (e) {
      return e.message;
    }
  }
}

final familyMovementListViewModelProvider =
    StateNotifierProvider<
      FamilyMovementListViewModel,
      ViewState<List<FamilyMovementEntity>>
    >((ref) {
      return FamilyMovementListViewModel(ref.watch(familyRepositoryProvider));
    });

final familyInvitationsProvider = FutureProvider<List<FamilyInvitationEntity>>((
  ref,
) {
  return ref.watch(familyRepositoryProvider).getInvitations();
});

final familyCategoriesProvider = FutureProvider((ref) {
  return ref.watch(familyRepositoryProvider).getFamilyCategories();
});

final treasuryOperationsProvider =
    FutureProvider<List<TreasuryOperationEntity>>((ref) {
      return ref.watch(familyRepositoryProvider).getTreasuryOperations();
    });

final familyBudgetsProvider = FutureProvider<List<FamilyBudgetEntity>>((ref) {
  return ref.watch(familyRepositoryProvider).getFamilyBudgets();
});
