import '../entities/user_entity.dart';

/// Contrato de autenticación. La UI y los ViewModels dependen solo de esta
/// abstracción; hoy la implementa un mock, mañana un servicio HTTP.
abstract class AuthRepository {
  Future<UserEntity> login({required String email, required String password});
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
  });
  Future<void> sendPasswordRecovery({required String email});
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<UserEntity> currentUser();
  Future<void> logout();

  /// Elimina la cuenta del usuario actual. Requiere reingresar la
  /// contraseña como verificación adicional de identidad.
  Future<void> deleteAccount({required String password});
}
