import 'family_entity.dart';

/// Filtros combinables para movimientos de la caja compartida.
class FamilyMovementFilters {
  final String? memberId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId;
  final String? accountId;
  final FamilyMovementType? type;

  const FamilyMovementFilters({
    this.memberId,
    this.startDate,
    this.endDate,
    this.categoryId,
    this.accountId,
    this.type,
  });

  bool get hasFilters =>
      memberId != null ||
      startDate != null ||
      categoryId != null ||
      accountId != null ||
      type != null;

  bool matches(FamilyMovementEntity m) {
    if (memberId != null && m.createdByMemberId != memberId) return false;
    if (categoryId != null && m.category.id != categoryId) return false;
    if (accountId != null && m.account.id != accountId) return false;
    if (type != null && m.type != type) return false;
    if (startDate != null && m.date.isBefore(startDate!)) return false;
    if (endDate != null && m.date.isAfter(endDate!)) return false;
    return true;
  }

  FamilyMovementFilters copyWith({
    String? memberId,
    bool clearMember = false,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDates = false,
    String? categoryId,
    bool clearCategory = false,
    String? accountId,
    bool clearAccount = false,
    FamilyMovementType? type,
    bool clearType = false,
  }) {
    return FamilyMovementFilters(
      memberId: clearMember ? null : (memberId ?? this.memberId),
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      accountId: clearAccount ? null : (accountId ?? this.accountId),
      type: clearType ? null : (type ?? this.type),
    );
  }
}

abstract class FamilyRepository {
  Future<FamilyGroupEntity?> getFamilyGroup();
  Future<FamilyGroupEntity> createFamilyGroup(String name);

  Future<FamilyGroupEntity> addMember({
    required String name,
    required String email,
    required FamilyRole role,
  });
  Future<FamilyGroupEntity> updateMemberRole(String memberId, FamilyRole role);
  Future<FamilyGroupEntity> removeMember(String memberId);

  Future<FamilyGroupEntity> addSharedAccount(String accountId);
  Future<FamilyGroupEntity> removeSharedAccount(String accountId);

  Future<List<FamilyMovementEntity>> getFamilyMovements();
  Future<FamilyMovementEntity> addFamilyMovement(FamilyMovementEntity movement);
  Future<FamilyInvitationEntity> createInvitation({
    required String email,
    required String userIdentifier,
    String invitedName = 'Integrante invitado',
    FamilyRole role = FamilyRole.member,
  });
  Future<FamilyGroupEntity> acceptInvitation(String code);
  Future<void> revokeInvitation(String invitationId);
  Future<List<FamilyInvitationEntity>> getInvitations();
  Future<void> deleteFamilyGroup();
  Future<List<TreasuryOperationEntity>> getTreasuryOperations();
  Future<TreasuryOperationEntity> addTreasuryOperation(
    TreasuryOperationEntity operation,
  );
  Future<List<FamilyBudgetEntity>> getFamilyBudgets();
  Future<FamilyBudgetEntity> saveFamilyBudget(FamilyBudgetEntity budget);
}
