/// Representa un error de dominio. Los repositories (mock u HTTP en el
/// futuro) lanzan este tipo para que los ViewModels lo traten de forma
/// uniforme, sin acoplarse al origen del dato.
class AppFailure implements Exception {
  final String message;
  final String? code;

  const AppFailure(this.message, {this.code});

  @override
  String toString() => 'AppFailure($code): $message';
}
