import '../../../core/errors/app_failure.dart';
import '../../../mock/mock_data.dart';
import '../../accounts/domain/account_repository.dart';
import '../domain/family_entity.dart';
import '../domain/family_repository.dart';

class MockFamilyRepository implements FamilyRepository {
  final AccountRepository _accountRepository;

  FamilyGroupEntity? _group;
  final List<FamilyMovementEntity> _movements = [];
  final List<FamilyInvitationEntity> _invitations = [];
  final List<TreasuryOperationEntity> _treasury = [];
  final List<FamilyBudgetEntity> _budgets = [
    const FamilyBudgetEntity(
      id: 'fb_1',
      categoryName: 'Alimentación',
      amount: 3500000,
      spent: 1920000,
    ),
    const FamilyBudgetEntity(
      id: 'fb_2',
      categoryName: 'Servicios',
      amount: 1800000,
      spent: 1350000,
    ),
  ];
  int _memberSequence = 100;
  int _movementSequence = 100;

  MockFamilyRepository(this._accountRepository);

  @override
  Future<FamilyGroupEntity?> getFamilyGroup() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _group;
  }

  @override
  Future<FamilyGroupEntity> createFamilyGroup(String name) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (_group != null) {
      throw const AppFailure(
        'Ya formás parte de un grupo familiar.',
        code: 'group_exists',
      );
    }
    _group = FamilyGroupEntity(
      id: 'fam_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      members: [
        FamilyMemberEntity(
          id: 'you',
          name: MockData.userName,
          email: MockData.userEmail,
          role: FamilyRole.owner,
          joinedAt: DateTime.now(),
        ),
      ],
    );
    return _group!;
  }

  FamilyGroupEntity _requireGroup() {
    if (_group == null) {
      throw const AppFailure('No pertenecés a ningún grupo familiar todavía.');
    }
    return _group!;
  }

  @override
  Future<FamilyGroupEntity> addMember({
    required String name,
    required String email,
    required FamilyRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final group = _requireGroup();
    if (group.members.any(
      (m) => m.email.trim().toLowerCase() == email.trim().toLowerCase(),
    )) {
      throw const AppFailure(
        'Ya existe un integrante con ese correo.',
        code: 'duplicate_member',
      );
    }
    final member = FamilyMemberEntity(
      id: 'mem_${_memberSequence++}',
      name: name,
      email: email,
      role: role,
      joinedAt: DateTime.now(),
    );
    _group = group.copyWith(members: [...group.members, member]);
    return _group!;
  }

  @override
  Future<FamilyGroupEntity> updateMemberRole(
    String memberId,
    FamilyRole role,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final group = _requireGroup();
    final members = group.members
        .map((m) => m.id == memberId ? m.copyWith(role: role) : m)
        .toList();
    _group = group.copyWith(members: members);
    return _group!;
  }

  @override
  Future<FamilyGroupEntity> removeMember(String memberId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final group = _requireGroup();
    final member = group.members.firstWhere(
      (m) => m.id == memberId,
      orElse: () => throw const AppFailure('Integrante no encontrado.'),
    );
    if (member.role == FamilyRole.owner) {
      throw const AppFailure(
        'No podés quitar al propietario del grupo.',
        code: 'cannot_remove_owner',
      );
    }
    _group = group.copyWith(
      members: group.members.where((m) => m.id != memberId).toList(),
    );
    return _group!;
  }

  @override
  Future<FamilyGroupEntity> addSharedAccount(String accountId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final group = _requireGroup();
    if (group.sharedAccounts.any((a) => a.id == accountId)) return group;
    final accounts = await _accountRepository.getAccounts();
    final account = accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => throw const AppFailure('Cuenta no encontrada.'),
    );
    _group = group.copyWith(sharedAccounts: [...group.sharedAccounts, account]);
    return _group!;
  }

  @override
  Future<FamilyGroupEntity> removeSharedAccount(String accountId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final group = _requireGroup();
    _group = group.copyWith(
      sharedAccounts: group.sharedAccounts
          .where((a) => a.id != accountId)
          .toList(),
    );
    return _group!;
  }

  @override
  Future<List<FamilyMovementEntity>> getFamilyMovements() async {
    await Future.delayed(const Duration(milliseconds: 450));
    _requireGroup();
    final sorted = [..._movements]..sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(sorted);
  }

  @override
  Future<FamilyMovementEntity> addFamilyMovement(
    FamilyMovementEntity movement,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final group = _requireGroup();
    if (!group.sharedAccounts.any((a) => a.id == movement.account.id)) {
      throw const AppFailure(
        'Seleccioná una cuenta compartida del grupo.',
        code: 'account_not_shared',
      );
    }
    final created = FamilyMovementEntity(
      id: 'fmov_${_movementSequence++}',
      type: movement.type,
      amount: movement.amount,
      date: movement.date,
      category: movement.category,
      account: movement.account,
      description: movement.description,
      createdByMemberId: movement.createdByMemberId,
      createdByMemberName: movement.createdByMemberName,
    );
    _movements.add(created);
    return created;
  }

  @override
  Future<FamilyInvitationEntity> createInvitation({
    required String email,
    required String userIdentifier,
    String invitedName = 'Integrante invitado',
    FamilyRole role = FamilyRole.member,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _requireGroup();
    if (email.trim().isEmpty && userIdentifier.trim().isEmpty) {
      throw const AppFailure('Ingresá un correo o identificador de usuario.');
    }
    final invitation = FamilyInvitationEntity(
      id: 'inv_${_memberSequence++}',
      email: email.trim(),
      userIdentifier: userIdentifier.trim(),
      code: '${100000 + (_memberSequence % 899999)}',
      status: FamilyInvitationStatus.pending,
      createdAt: DateTime.now(),
      invitedName: invitedName,
      role: role,
    );
    _invitations.insert(0, invitation);
    return invitation;
  }

  @override
  Future<FamilyGroupEntity> acceptInvitation(String code) async {
    await Future.delayed(const Duration(milliseconds: 550));
    final index = _invitations.indexWhere(
      (item) =>
          item.code == code.trim() &&
          item.status == FamilyInvitationStatus.pending,
    );
    if (index < 0) {
      throw const AppFailure(
        'La invitación no existe, expiró o ya fue utilizada.',
        code: 'invalid_invitation',
      );
    }
    final invitation = _invitations[index];
    _invitations[index] = invitation.copyWith(
      status: FamilyInvitationStatus.accepted,
    );
    return addMember(
      name: invitation.invitedName,
      email: invitation.email.isEmpty
          ? '${invitation.userIdentifier}@demo.local'
          : invitation.email,
      role: invitation.role,
    );
  }

  @override
  Future<void> revokeInvitation(String invitationId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _invitations.indexWhere((item) => item.id == invitationId);
    if (index < 0) throw const AppFailure('Invitación no encontrada.');
    if (_invitations[index].status != FamilyInvitationStatus.pending) {
      throw const AppFailure('Sólo se pueden revocar invitaciones pendientes.');
    }
    _invitations[index] = _invitations[index].copyWith(
      status: FamilyInvitationStatus.revoked,
    );
  }

  @override
  Future<List<FamilyInvitationEntity>> getInvitations() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_invitations);
  }

  @override
  Future<void> deleteFamilyGroup() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _group = null;
    _movements.clear();
    _invitations.clear();
    _treasury.clear();
  }

  double get _treasuryBalance => _treasury.fold(0, (sum, operation) {
    return sum +
        (operation.type == TreasuryOperationType.contribution
            ? operation.amount
            : -operation.amount);
  });

  @override
  Future<List<TreasuryOperationEntity>> getTreasuryOperations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _requireGroup();
    return List.unmodifiable(_treasury);
  }

  @override
  Future<TreasuryOperationEntity> addTreasuryOperation(
    TreasuryOperationEntity operation,
  ) async {
    await Future.delayed(const Duration(milliseconds: 450));
    _requireGroup();
    if (operation.amount <= 0) {
      throw const AppFailure('Ingresá un monto válido.');
    }
    if (operation.type != TreasuryOperationType.contribution &&
        !operation.actorRole.canManageGroup) {
      throw const AppFailure(
        'Sólo un administrador puede retirar o utilizar fondos de la caja.',
        code: 'forbidden',
      );
    }
    if (operation.type != TreasuryOperationType.contribution &&
        operation.otpVerificationId == null) {
      throw const AppFailure(
        'Esta operación requiere verificación OTP.',
        code: 'otp_required',
      );
    }
    if (operation.type != TreasuryOperationType.contribution &&
        operation.amount > _treasuryBalance) {
      throw const AppFailure(
        'La caja compartida no tiene saldo suficiente.',
        code: 'insufficient_funds',
      );
    }
    final created = TreasuryOperationEntity(
      id: 'tre_${_movementSequence++}',
      type: operation.type,
      amount: operation.amount,
      description: operation.description,
      memberName: operation.memberName,
      date: DateTime.now(),
      accountId: operation.accountId,
      accountName: operation.accountName,
      otpVerificationId: operation.otpVerificationId,
      actorRole: operation.actorRole,
    );
    _treasury.insert(0, created);
    return created;
  }

  @override
  Future<List<FamilyBudgetEntity>> getFamilyBudgets() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _requireGroup();
    return List.unmodifiable(_budgets);
  }

  @override
  Future<FamilyBudgetEntity> saveFamilyBudget(FamilyBudgetEntity budget) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _requireGroup();
    final saved = FamilyBudgetEntity(
      id: budget.id.isEmpty ? 'fb_${_budgets.length + 1}' : budget.id,
      categoryName: budget.categoryName,
      amount: budget.amount,
      spent: budget.spent,
    );
    final index = _budgets.indexWhere((item) => item.id == saved.id);
    if (index < 0) {
      _budgets.add(saved);
    } else {
      _budgets[index] = saved;
    }
    return saved;
  }
}
