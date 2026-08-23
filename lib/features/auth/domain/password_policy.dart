class PasswordPolicy {
  PasswordPolicy._();

  static const requirements =
      'Usá entre 12 y 128 caracteres, con mayúscula, minúscula, número y '
      'carácter especial. No incluyas tu nombre ni tu correo.';

  static String? validate({
    required String password,
    required String email,
    required String name,
  }) {
    if (password.length < 12 || password.length > 128) {
      return 'La contraseña debe tener entre 12 y 128 caracteres.';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'La contraseña debe contener al menos una letra mayúscula.';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'La contraseña debe contener al menos una letra minúscula.';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'La contraseña debe contener al menos un número.';
    }
    if (!password.contains(RegExp(r'[^A-Za-z0-9]'))) {
      return 'La contraseña debe contener al menos un carácter especial.';
    }

    const commonPasswords = {
      'password',
      'password123',
      '12345678',
      '123456789',
      'qwerty123',
      'admin123',
      'contraseña',
      'contrasena',
      'finanzas123',
    };
    final normalized = password
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toLowerCase();
    if (commonPasswords.contains(password.toLowerCase()) ||
        commonPasswords.contains(normalized)) {
      return 'La contraseña es demasiado común.';
    }

    final normalizedPassword = password.toLowerCase();
    final localPart = email.trim().split('@').first.toLowerCase();
    final trimmedName = name.trim().toLowerCase();
    if ((localPart.length >= 4 && normalizedPassword.contains(localPart)) ||
        (trimmedName.length >= 4 && normalizedPassword.contains(trimmedName))) {
      return 'La contraseña no debe contener tu nombre ni tu correo.';
    }
    return null;
  }
}
