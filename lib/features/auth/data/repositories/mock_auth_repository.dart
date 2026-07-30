import '../../../../core/errors/app_failure.dart';
import '../../../../mock/mock_data.dart';
import '../../../family/domain/family_entity.dart';
import '../../../family/domain/family_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class MockAuthRepository implements AuthRepository {
  final FamilyRepository _familyRepository;
  final Map<String, UserModel> _users = {};
  final Map<String, String> _registeredPasswords = {};

  MockAuthRepository(this._familyRepository) {
    _users[_mockUser.email.toLowerCase()] = _mockUser;
  }

  final _mockUser = UserModel(
    id: MockData.userId,
    name: MockData.userName,
    email: MockData.userEmail,
    currency: MockData.currencyCode,
    language: MockData.language,
    location: MockData.userLocation,
  );

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final normalizedEmail = email.trim().toLowerCase();
    final user = _users[normalizedEmail];
    final registeredPassword = _registeredPasswords[normalizedEmail];
    if (user == null ||
        password.length < 4 ||
        (registeredPassword != null && registeredPassword != password)) {
      throw const AppFailure(
        'Correo o contraseña incorrectos.',
        code: 'invalid_credentials',
      );
    }
    return user.toEntity();
  }

  @override
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1100));
    if (password.length < 6) {
      throw const AppFailure(
        'La contraseña debe tener al menos 6 caracteres.',
        code: 'weak_password',
      );
    }
    final user = UserModel(
      id: MockData.userId,
      name: name,
      email: email,
      currency: MockData.currencyCode,
      language: MockData.language,
      location: MockData.userLocation,
    );
    final normalizedEmail = email.trim().toLowerCase();
    _users[normalizedEmail] = user;
    _registeredPasswords[normalizedEmail] = password;
    return user.toEntity();
  }

  @override
  Future<void> sendPasswordRecovery({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (token.trim().length < 6) {
      throw const AppFailure(
        'El código de recuperación no es válido.',
        code: 'invalid_token',
      );
    }
    if (newPassword.length < 6) {
      throw const AppFailure(
        'La nueva contraseña debe tener al menos 6 caracteres.',
        code: 'weak_password',
      );
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (currentPassword.length < 4) {
      throw const AppFailure(
        'La contraseña actual no es correcta.',
        code: 'invalid_credentials',
      );
    }
    if (newPassword.length < 6) {
      throw const AppFailure(
        'La nueva contraseña debe tener al menos 6 caracteres.',
        code: 'weak_password',
      );
    }
  }

  @override
  Future<UserEntity> currentUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockUser.toEntity();
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<void> deleteAccount({required String password}) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (password.length < 4) {
      throw const AppFailure(
        'La contraseña ingresada no es correcta.',
        code: 'invalid_credentials',
      );
    }

    final group = await _familyRepository.getFamilyGroup();
    if (group != null) {
      final me = group.members.where((m) => m.id == 'you').toList();
      final isOwner = me.isNotEmpty && me.first.role == FamilyRole.owner;
      if (isOwner && group.members.length > 1) {
        throw const AppFailure(
          'Sos propietario de un grupo familiar con otros integrantes. Transferí la propiedad o eliminá el grupo antes de eliminar tu cuenta.',
          code: 'family_owner_conflict',
        );
      }
    }

    // En un backend real, este paso eliminaría o anonimizaría los datos
    // del usuario (movimientos, comprobantes, cuentas, membresías) según
    // las políticas de retención vigentes.
  }
}
