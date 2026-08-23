import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../accounts/domain/account_entity.dart';
import '../../categories/domain/category_entity.dart';
import '../../auth/domain/user_alias_policy.dart';
import '../domain/family_entity.dart';
import '../domain/family_repository.dart';

class ApiFamilyRepository implements FamilyRepository {
  final ApiClient _api;
  final Map<String, int> _groupVersions = {};
  final Map<String, int> _memberVersions = {};
  final Map<String, int> _invitationVersions = {};
  final Map<String, int> _sharedAccountVersions = {};
  final Map<String, int> _budgetVersions = {};
  String? _activeGroupId;

  ApiFamilyRepository(this._api);

  @override
  Future<FamilyGroupEntity?> getFamilyGroup() async {
    final page = (await _api.get('/grupos-familiares')).object;
    final items = page['datos'] as List<dynamic>? ?? const [];
    if (items.isEmpty) {
      _activeGroupId = null;
      return null;
    }
    return _loadGroup(items.first as Map<String, dynamic>);
  }

  @override
  Future<FamilyGroupEntity> createFamilyGroup(String name) async {
    final response = await _api.post(
      '/grupos-familiares',
      body: {'nombre': name},
    );
    return _loadGroup(response.object);
  }

  Future<FamilyGroupEntity> _loadGroup(Map<String, dynamic> json) async {
    final id = json['id'] as String;
    _activeGroupId = id;
    _groupVersions[id] = (json['version'] as num).toInt();
    final role = _roleFromApi(json['miRol'] as String);
    final members = await _loadMembers(id);
    final sharedAccounts = await _loadSharedAccounts(id);
    final candidates = members.where((member) => member.role == role).toList();
    final current = candidates.length == 1 ? candidates.single : null;
    return FamilyGroupEntity(
      id: id,
      name: json['nombre'] as String,
      members: members,
      sharedAccounts: sharedAccounts,
      currentRole: role,
      currentMemberId: current?.id,
      version: (json['version'] as num).toInt(),
    );
  }

  Future<List<FamilyMemberEntity>> _loadMembers(String groupId) async {
    final page = (await _api.get(
      '/grupos-familiares/$groupId/integrantes',
    )).object;
    return (page['datos'] as List<dynamic>? ?? const []).map((item) {
      final json = item as Map<String, dynamic>;
      final user = json['usuario'] as Map<String, dynamic>;
      final id = json['id'] as String;
      final version = (json['version'] as num).toInt();
      _memberVersions[id] = version;
      return FamilyMemberEntity(
        id: id,
        userId: user['id'] as String,
        name: user['nombre'] as String,
        email: user['correo'] as String,
        role: _roleFromApi(json['rol'] as String),
        joinedAt: DateTime.parse(json['incorporadoEn'] as String),
        version: version,
      );
    }).toList();
  }

  Future<List<AccountEntity>> _loadSharedAccounts(String groupId) async {
    final page = (await _api.get(
      '/grupos-familiares/$groupId/cuentas-compartidas',
    )).object;
    return (page['datos'] as List<dynamic>? ?? const []).map((item) {
      final json = item as Map<String, dynamic>;
      final account = json['cuenta'] as Map<String, dynamic>;
      final id = account['id'] as String;
      _sharedAccountVersions[id] = (json['version'] as num).toInt();
      final type = _accountType(account['tipo'] as String);
      return AccountEntity(
        id: id,
        name: account['nombre'] as String,
        type: type,
        icon: type.defaultIcon,
        initialBalance: 0,
      );
    }).toList();
  }

  @override
  Future<FamilyGroupEntity> addMember({
    required String name,
    required String email,
    required FamilyRole role,
  }) async {
    await createInvitation(
      email: email,
      userIdentifier: '',
      invitedName: name,
      role: role,
    );
    return (await getFamilyGroup())!;
  }

  @override
  Future<FamilyGroupEntity> updateMemberRole(
    String memberId,
    FamilyRole role,
  ) async {
    final groupId = await _groupId();
    final version = _memberVersions[memberId] ?? 1;
    await _api.patch(
      '/grupos-familiares/$groupId/integrantes/$memberId',
      body: {'rol': _roleToApi(role)},
      headers: {'If-Match': '"$version"'},
    );
    return (await getFamilyGroup())!;
  }

  @override
  Future<FamilyGroupEntity> removeMember(String memberId) async {
    final groupId = await _groupId();
    final version = _memberVersions[memberId] ?? 1;
    await _api.delete(
      '/grupos-familiares/$groupId/integrantes/$memberId',
      headers: {'If-Match': '"$version"'},
    );
    return (await getFamilyGroup())!;
  }

  @override
  Future<FamilyGroupEntity> addSharedAccount(String accountId) async {
    final groupId = await _groupId();
    await _api.post(
      '/grupos-familiares/$groupId/cuentas-compartidas',
      body: {'cuentaId': accountId},
    );
    return (await getFamilyGroup())!;
  }

  @override
  Future<FamilyGroupEntity> removeSharedAccount(String accountId) async {
    final groupId = await _groupId();
    final version = _sharedAccountVersions[accountId] ?? 1;
    await _api.delete(
      '/grupos-familiares/$groupId/cuentas-compartidas/$accountId',
      headers: {'If-Match': '"$version"'},
    );
    return (await getFamilyGroup())!;
  }

  @override
  Future<List<CategoryEntity>> getFamilyCategories() async {
    final groupId = await _groupId();
    final page = (await _api.get(
      '/grupos-familiares/$groupId/categorias',
    )).object;
    return (page['datos'] as List<dynamic>? ?? const [])
        .map((item) => _categoryFromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<FamilyMovementEntity>> getFamilyMovements() async {
    final group = await getFamilyGroup();
    if (group == null) throw const AppFailure('No pertenecés a un grupo.');
    final categories = await getFamilyCategories();
    final page = (await _api.get(
      '/grupos-familiares/${group.id}/movimientos',
    )).object;
    return (page['datos'] as List<dynamic>? ?? const []).map((item) {
      final json = item as Map<String, dynamic>;
      final account = group.sharedAccounts.firstWhere(
        (value) => value.id == json['cuentaId'],
      );
      final categoryIds = (json['categoriaIds'] as List<dynamic>).toSet();
      final category = categories.firstWhere(
        (value) => categoryIds.contains(value.id),
      );
      final creatorId = json['creadoPorId'] as String;
      final creator = group.members
          .where((value) => value.userId == creatorId)
          .firstOrNull;
      return FamilyMovementEntity(
        id: json['id'] as String,
        type: json['tipo'] == 'ingreso'
            ? FamilyMovementType.income
            : FamilyMovementType.expense,
        amount: (json['monto'] as num).toDouble(),
        date: DateTime.parse(json['fecha'] as String),
        category: category,
        account: account,
        description: json['descripcion'] as String,
        createdByMemberId: creator?.id ?? creatorId,
        createdByMemberName: creator?.name ?? 'Integrante',
        version: (json['version'] as num).toInt(),
      );
    }).toList();
  }

  @override
  Future<FamilyMovementEntity> addFamilyMovement(
    FamilyMovementEntity movement,
  ) async {
    final groupId = await _groupId();
    final response = await _api.post(
      '/grupos-familiares/$groupId/movimientos',
      headers: {'Idempotency-Key': _idempotencyKey('movement')},
      body: {
        'cuentaId': movement.account.id,
        'tipo': movement.type == FamilyMovementType.income
            ? 'ingreso'
            : 'gasto',
        'monto': movement.amount.round(),
        'descripcion': movement.description,
        'fecha': _date(movement.date),
        'categoriaIds': [movement.category.id],
      },
    );
    final createdId = response.object['id'] as String;
    return (await getFamilyMovements()).firstWhere(
      (movement) => movement.id == createdId,
    );
  }

  @override
  Future<FamilyInvitationEntity> createInvitation({
    required String email,
    required String userIdentifier,
    String invitedName = 'Integrante invitado',
    FamilyRole role = FamilyRole.member,
  }) async {
    final identifier = userIdentifier.trim();
    final uuid = _uuidOrNull(identifier);
    final alias = uuid == null && identifier.isNotEmpty
        ? UserAliasPolicy.normalize(identifier)
        : null;
    if (email.trim().isEmpty && uuid == null && alias == null) {
      throw const AppFailure('Ingresá el alias único del usuario.');
    }
    final groupId = await _groupId();
    final response = await _api.post(
      '/grupos-familiares/$groupId/invitaciones',
      headers: {'Idempotency-Key': _idempotencyKey('invitation')},
      body: {
        'correo': email.trim().isEmpty ? null : email.trim(),
        'identificadorUsuario': uuid,
        'alias': alias,
        'rol': _roleToApi(role),
      },
    );
    final json = response.object;
    final location = response.headers['location'] ?? '';
    final token = location
        .split('/')
        .where((part) => part.isNotEmpty)
        .lastOrNull;
    final invitation = FamilyInvitationEntity(
      id: json['id'] as String,
      email: json['correo'] as String? ?? '',
      userIdentifier: _invitationIdentifier(json),
      code: json['codigo'] as String,
      status: _invitationStatus(json['estado'] as String),
      createdAt: DateTime.now(),
      invitedName: invitedName,
      role: role,
      token: token,
      version: (json['version'] as num).toInt(),
    );
    _invitationVersions[invitation.id] = invitation.version;
    return invitation;
  }

  @override
  Future<FamilyGroupEntity> acceptInvitation(String token, String code) async {
    await _api.post(
      '/invitaciones-familiares/$token/aceptaciones',
      body: {'codigo': code},
    );
    _activeGroupId = null;
    return (await getFamilyGroup())!;
  }

  @override
  Future<void> revokeInvitation(String invitationId) async {
    final groupId = await _groupId();
    await _api.delete(
      '/grupos-familiares/$groupId/invitaciones/$invitationId',
      headers: {'If-Match': '"${_invitationVersions[invitationId] ?? 1}"'},
    );
  }

  @override
  Future<List<FamilyInvitationEntity>> getInvitations() async {
    final groupId = await _groupId();
    final page = (await _api.get(
      '/grupos-familiares/$groupId/invitaciones',
    )).object;
    return (page['datos'] as List<dynamic>? ?? const []).map((item) {
      final json = item as Map<String, dynamic>;
      final id = json['id'] as String;
      final version = (json['version'] as num).toInt();
      _invitationVersions[id] = version;
      return FamilyInvitationEntity(
        id: id,
        email: json['correo'] as String? ?? '',
        userIdentifier: _invitationIdentifier(json),
        code: '',
        status: _invitationStatus(json['estado'] as String),
        createdAt: DateTime.parse(
          json['expiraEn'] as String,
        ).subtract(const Duration(days: 7)),
        role: _roleFromApi(json['rol'] as String),
        version: version,
      );
    }).toList();
  }

  @override
  Future<void> deleteFamilyGroup(String otpVerificationId) async {
    final groupId = await _groupId();
    final version = _groupVersions[groupId] ?? 1;
    await _api.post(
      '/grupos-familiares/$groupId/eliminaciones',
      headers: {
        'If-Match': '"$version"',
        'Idempotency-Key': _idempotencyKey('delete-group'),
      },
      body: {'verificacionOtpId': otpVerificationId},
    );
    _activeGroupId = null;
  }

  @override
  Future<List<TreasuryOperationEntity>> getTreasuryOperations() async {
    final groupId = await _groupId();
    final page = (await _api.get(
      '/grupos-familiares/$groupId/operaciones-caja',
    )).object;
    return (page['datos'] as List<dynamic>? ?? const []).map((item) {
      final json = item as Map<String, dynamic>;
      final user = json['realizadoPor'] as Map<String, dynamic>;
      return TreasuryOperationEntity(
        id: json['id'] as String,
        type: json['tipo'] == 'aporte'
            ? TreasuryOperationType.contribution
            : TreasuryOperationType.withdrawal,
        amount: (json['monto'] as num).toDouble(),
        description: json['descripcion'] as String,
        memberName: user['nombre'] as String,
        date: DateTime.parse(json['creadoEn'] as String),
      );
    }).toList();
  }

  @override
  Future<TreasuryOperationEntity> addTreasuryOperation(
    TreasuryOperationEntity operation,
  ) async {
    if (operation.type == TreasuryOperationType.sharedExpense) {
      throw const AppFailure(
        'Registrá primero el gasto como movimiento familiar.',
        code: 'shared_expense_not_supported',
      );
    }
    if (operation.accountId == null) {
      throw const AppFailure('Seleccioná una cuenta privada.');
    }
    final groupId = await _groupId();
    final response = await _api.post(
      '/grupos-familiares/$groupId/operaciones-caja',
      headers: {'Idempotency-Key': _idempotencyKey('treasury')},
      body: {
        'tipo': operation.type == TreasuryOperationType.contribution
            ? 'aporte'
            : 'retiro',
        'monto': operation.amount.round(),
        'descripcion': operation.description,
        'cuentaPrivadaId': operation.accountId,
        'movimientoFamiliarId': null,
        'verificacionOtpId': operation.otpVerificationId,
      },
    );
    final json = response.object;
    final user = json['realizadoPor'] as Map<String, dynamic>;
    return TreasuryOperationEntity(
      id: json['id'] as String,
      type: operation.type,
      amount: (json['monto'] as num).toDouble(),
      description: json['descripcion'] as String,
      memberName: user['nombre'] as String,
      date: DateTime.parse(json['creadoEn'] as String),
      accountId: operation.accountId,
      accountName: operation.accountName,
      otpVerificationId: operation.otpVerificationId,
      actorRole: operation.actorRole,
    );
  }

  @override
  Future<List<FamilyBudgetEntity>> getFamilyBudgets() async {
    final groupId = await _groupId();
    final page = (await _api.get(
      '/grupos-familiares/$groupId/presupuestos',
    )).object;
    return (page['datos'] as List<dynamic>? ?? const [])
        .map((item) => _budgetFromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<FamilyBudgetEntity> saveFamilyBudget(FamilyBudgetEntity budget) async {
    if (budget.categoryId == null) {
      throw const AppFailure('Seleccioná una categoría familiar.');
    }
    final groupId = await _groupId();
    final body = {
      'nombre': budget.categoryName,
      'monto': budget.amount.round(),
      'periodo': budget.period,
      'categoriaIds': [budget.categoryId],
    };
    final response = budget.id.isEmpty
        ? await _api.post(
            '/grupos-familiares/$groupId/presupuestos',
            body: body,
          )
        : await _api.patch(
            '/grupos-familiares/$groupId/presupuestos/${budget.id}',
            body: body,
            headers: {
              'If-Match': '"${_budgetVersions[budget.id] ?? budget.version}"',
            },
          );
    return _budgetFromJson(response.object);
  }

  Future<String> _groupId() async {
    if (_activeGroupId case final id?) return id;
    final group = await getFamilyGroup();
    if (group == null) throw const AppFailure('No pertenecés a un grupo.');
    return group.id;
  }

  FamilyBudgetEntity _budgetFromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final version = (json['version'] as num).toInt();
    final categories = json['categorias'] as List<dynamic>;
    final category = categories.first as Map<String, dynamic>;
    _budgetVersions[id] = version;
    return FamilyBudgetEntity(
      id: id,
      categoryId: category['id'] as String,
      categoryName: json['nombre'] as String,
      amount: (json['monto'] as num).toDouble(),
      spent: (json['gastado'] as num).toDouble(),
      period: json['periodo'] as String,
      version: version,
    );
  }

  CategoryEntity _categoryFromJson(Map<String, dynamic> json) => CategoryEntity(
    id: json['id'] as String,
    name: json['nombre'] as String,
    icon: _icon(json['icono'] as String?),
    color: _color(json['color'] as String?),
    type: switch (json['tipo']) {
      'ingreso' => CategoryType.income,
      'gasto' => CategoryType.expense,
      _ => CategoryType.both,
    },
    inUse: true,
  );

  FamilyRole _roleFromApi(String value) => switch (value) {
    'propietario' => FamilyRole.owner,
    'administrador' => FamilyRole.admin,
    _ => FamilyRole.member,
  };

  String _roleToApi(FamilyRole value) => switch (value) {
    FamilyRole.owner => 'propietario',
    FamilyRole.admin => 'administrador',
    FamilyRole.member => 'integrante',
  };

  String _invitationIdentifier(Map<String, dynamic> json) {
    final alias = json['aliasDestino'] as String?;
    if (alias != null && alias.isNotEmpty) return '@$alias';
    return json['usuarioDestino'] as String? ?? '';
  }

  FamilyInvitationStatus _invitationStatus(String value) => switch (value) {
    'aceptada' => FamilyInvitationStatus.accepted,
    'expirada' => FamilyInvitationStatus.expired,
    'revocada' || 'cancelada' => FamilyInvitationStatus.revoked,
    _ => FamilyInvitationStatus.pending,
  };

  AccountType _accountType(String value) => switch (value) {
    'efectivo' => AccountType.cash,
    'cuenta-corriente' => AccountType.checkingAccount,
    'cuenta-ahorro' => AccountType.savingsAccount,
    'tarjeta-debito' => AccountType.debitCard,
    'billetera-digital' => AccountType.digitalWallet,
    _ => AccountType.other,
  };

  IconData _icon(String? value) => switch (value) {
    'restaurant' => Icons.restaurant_outlined,
    'home' => Icons.home_outlined,
    'payments' => Icons.payments_outlined,
    _ => Icons.category_outlined,
  };

  Color _color(String? value) {
    final normalized = (value ?? '').replaceFirst('#', '');
    final parsed = int.tryParse(normalized, radix: 16);
    return parsed == null ? Colors.blueGrey : Color(0xff000000 | parsed);
  }

  String? _uuidOrNull(String value) {
    final normalized = value.trim();
    return RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
        ).hasMatch(normalized)
        ? normalized
        : null;
  }

  String _idempotencyKey(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-'
      '${Random.secure().nextInt(1 << 32)}';

  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
