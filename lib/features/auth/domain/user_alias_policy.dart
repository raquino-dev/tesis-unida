class UserAliasPolicy {
  static const requirements =
      'Entre 3 y 24 caracteres. Debe comenzar con una letra y puede incluir números o guion bajo.';

  static String normalize(String value) {
    final trimmed = value.trim();
    return trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
  }

  static String? validate(String value) {
    final alias = normalize(value);
    if (alias.isEmpty) return 'Ingresá un alias único.';
    if (!RegExp(r'^[A-Za-z][A-Za-z0-9_]{2,23}$').hasMatch(alias)) {
      return requirements;
    }
    return null;
  }
}
