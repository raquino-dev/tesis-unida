import '../../domain/entities/user_entity.dart';

/// Modelo de datos. Hoy se construye desde mock; el día que exista API real
/// basta con implementar `fromJson` sin tocar el resto de la app.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String currency;
  final String language;
  final String location;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.currency,
    required this.language,
    required this.location,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      currency: json['currency'] as String,
      language: json['language'] as String,
      location: json['location'] as String,
    );
  }

  UserEntity toEntity() => UserEntity(
    id: id,
    name: name,
    email: email,
    currency: currency,
    language: language,
    location: location,
  );
}
