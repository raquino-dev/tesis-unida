class UserEntity {
  final String id;
  final String name;
  final String alias;
  final String email;
  final String currency;
  final String language;
  final String location;
  final int version;

  const UserEntity({
    required this.id,
    required this.name,
    this.alias = '',
    required this.email,
    required this.currency,
    required this.language,
    required this.location,
    this.version = 1,
  });

  String get formattedAlias => alias.isEmpty ? '' : '@$alias';

  UserEntity copyWith({String? name, String? alias, int? version}) =>
      UserEntity(
        id: id,
        name: name ?? this.name,
        alias: alias ?? this.alias,
        email: email,
        currency: currency,
        language: language,
        location: location,
        version: version ?? this.version,
      );
}
