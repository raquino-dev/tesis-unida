class UserEntity {
  final String id;
  final String name;
  final String email;
  final String currency;
  final String language;
  final String location;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.currency,
    required this.language,
    required this.location,
  });
}
