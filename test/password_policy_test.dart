import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_app/features/auth/domain/password_policy.dart';

void main() {
  group('PasswordPolicy', () {
    test('acepta una contraseña que cumple la política del servidor', () {
      expect(
        PasswordPolicy.validate(
          password: 'Piloto#Seguro2026',
          email: 'persona@example.com',
          name: 'Persona Prueba',
        ),
        isNull,
      );
    });

    test('explica cada requisito incumplido', () {
      expect(
        PasswordPolicy.validate(
          password: 'Corta#1',
          email: 'persona@example.com',
          name: 'Persona',
        ),
        contains('12'),
      );
      expect(
        PasswordPolicy.validate(
          password: 'minuscula#123',
          email: 'persona@example.com',
          name: 'Persona',
        ),
        contains('mayúscula'),
      );
      expect(
        PasswordPolicy.validate(
          password: 'MAYUSCULA#123',
          email: 'persona@example.com',
          name: 'Persona',
        ),
        contains('minúscula'),
      );
      expect(
        PasswordPolicy.validate(
          password: 'SinNumeros#Abc',
          email: 'persona@example.com',
          name: 'Persona',
        ),
        contains('número'),
      );
      expect(
        PasswordPolicy.validate(
          password: 'SinEspecial123',
          email: 'persona@example.com',
          name: 'Persona',
        ),
        contains('especial'),
      );
    });

    test('rechaza el nombre o la parte local del correo', () {
      expect(
        PasswordPolicy.validate(
          password: 'Persona#2026X',
          email: 'usuario@example.com',
          name: 'Persona',
        ),
        contains('nombre'),
      );
      expect(
        PasswordPolicy.validate(
          password: 'Usuario#2026X',
          email: 'usuario@example.com',
          name: 'Nombre',
        ),
        contains('correo'),
      );
    });
  });
}
