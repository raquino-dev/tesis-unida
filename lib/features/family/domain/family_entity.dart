import '../../accounts/domain/account_entity.dart';
import '../../categories/domain/category_entity.dart';

enum FamilyRole { owner, admin, member }

extension FamilyRoleLabel on FamilyRole {
  String get label {
    switch (this) {
      case FamilyRole.owner:
        return 'Propietario';
      case FamilyRole.admin:
        return 'Administrador';
      case FamilyRole.member:
        return 'Integrante';
    }
  }

  /// Solo propietario y administradores pueden gestionar integrantes y
  /// cuentas compartidas; cualquier integrante puede registrar movimientos.
  bool get canManageGroup =>
      this == FamilyRole.owner || this == FamilyRole.admin;
}

class FamilyMemberEntity {
  final String id;
  final String name;
  final String email;
  final FamilyRole role;
  final DateTime joinedAt;
  final int version;
  final String? userId;

  const FamilyMemberEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
    this.version = 1,
    this.userId,
  });

  FamilyMemberEntity copyWith({FamilyRole? role}) {
    return FamilyMemberEntity(
      id: id,
      name: name,
      email: email,
      role: role ?? this.role,
      joinedAt: joinedAt,
      version: version,
      userId: userId,
    );
  }
}

class FamilyGroupEntity {
  final String id;
  final String name;
  final List<FamilyMemberEntity> members;
  final List<AccountEntity> sharedAccounts;
  final FamilyRole currentRole;
  final String? currentMemberId;
  final int version;

  const FamilyGroupEntity({
    required this.id,
    required this.name,
    required this.members,
    this.sharedAccounts = const [],
    this.currentRole = FamilyRole.owner,
    this.currentMemberId,
    this.version = 1,
  });

  FamilyGroupEntity copyWith({
    String? name,
    List<FamilyMemberEntity>? members,
    List<AccountEntity>? sharedAccounts,
  }) {
    return FamilyGroupEntity(
      id: id,
      name: name ?? this.name,
      members: members ?? this.members,
      sharedAccounts: sharedAccounts ?? this.sharedAccounts,
      currentRole: currentRole,
      currentMemberId: currentMemberId,
      version: version,
    );
  }
}

/// Movimiento de la caja compartida. Se mantiene totalmente separado de
/// [MovementEntity] (movimientos personales) salvo que el usuario decida
/// compartir uno explícitamente; por ahora esa pasarela no está implementada.
class FamilyMovementEntity {
  final String id;
  final FamilyMovementType type;
  final double amount;
  final DateTime date;
  final CategoryEntity category;
  final AccountEntity account;
  final String description;
  final String createdByMemberId;
  final String createdByMemberName;
  final int version;

  const FamilyMovementEntity({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.category,
    required this.account,
    required this.description,
    required this.createdByMemberId,
    required this.createdByMemberName,
    this.version = 1,
  });
}

enum FamilyMovementType { expense, income }

enum FamilyInvitationStatus { pending, accepted, expired, revoked }

class FamilyInvitationEntity {
  final String id;
  final String email;
  final String userIdentifier;
  final String code;
  final FamilyInvitationStatus status;
  final DateTime createdAt;
  final String invitedName;
  final FamilyRole role;
  final String? token;
  final int version;

  const FamilyInvitationEntity({
    required this.id,
    required this.email,
    required this.userIdentifier,
    required this.code,
    required this.status,
    required this.createdAt,
    this.invitedName = 'Integrante invitado',
    this.role = FamilyRole.member,
    this.token,
    this.version = 1,
  });

  FamilyInvitationEntity copyWith({FamilyInvitationStatus? status}) {
    return FamilyInvitationEntity(
      id: id,
      email: email,
      userIdentifier: userIdentifier,
      code: code,
      status: status ?? this.status,
      createdAt: createdAt,
      invitedName: invitedName,
      role: role,
      token: token,
      version: version,
    );
  }
}

enum TreasuryOperationType { contribution, withdrawal, sharedExpense }

class TreasuryOperationEntity {
  final String id;
  final TreasuryOperationType type;
  final double amount;
  final String description;
  final String memberName;
  final DateTime date;
  final String? accountId;
  final String? accountName;
  final String? otpVerificationId;
  final FamilyRole actorRole;

  const TreasuryOperationEntity({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.memberName,
    required this.date,
    this.accountId,
    this.accountName,
    this.otpVerificationId,
    this.actorRole = FamilyRole.owner,
  });
}

class FamilyBudgetEntity {
  final String id;
  final String categoryName;
  final double amount;
  final double spent;
  final String? categoryId;
  final String period;
  final int version;

  const FamilyBudgetEntity({
    required this.id,
    required this.categoryName,
    required this.amount,
    required this.spent,
    this.categoryId,
    this.period = 'mensual',
    this.version = 1,
  });
  double get progress => amount <= 0 ? 0 : (spent / amount).clamp(0, 1.2);
}
