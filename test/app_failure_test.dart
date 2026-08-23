import 'package:finanzas_app/core/errors/app_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppFailure no expone códigos técnicos al usuario', () {
    const failure = AppFailure(
      'No pudimos completar la operación.',
      code: 'http_500',
    );

    expect(failure.toString(), 'No pudimos completar la operación.');
    expect(appErrorMessage(failure), 'No pudimos completar la operación.');
  });

  test('normaliza tildes descompuestas recibidas de servicios', () {
    const decomposed = AppFailure('No se completo\u0301 la operacio\u0301n.');

    expect(appErrorMessage(decomposed), 'No se completó la operación.');
  });

  test('repara texto UTF-8 interpretado incorrectamente como Latin-1', () {
    const malformed = AppFailure('OcurriÃ³ un error en la operaciÃ³n.');

    expect(malformed.message, 'Ocurrió un error en la operación.');
    expect(appErrorMessage(malformed), 'Ocurrió un error en la operación.');
  });

  test('oculta excepciones no controladas detrás de un mensaje en español', () {
    expect(
      appErrorMessage(Exception('SocketException: connection reset')),
      'Ocurrió un error inesperado. Intentá nuevamente.',
    );
  });

  test('no expone errores internos de persistencia', () {
    const failure = AppFailure(
      'An error occurred while saving the entity changes. '
      'See the inner exception for details.',
    );

    expect(failure.message, 'Ocurrió un error inesperado. Intentá nuevamente.');
  });

  test('permite un mensaje contextual ante un error técnico', () {
    const failure = AppFailure(
      'Npgsql.PostgresException: permission denied for schema sincronizacion',
    );

    expect(
      appErrorMessage(
        failure,
        fallback: 'No pudimos guardar la categoría. Intentá nuevamente.',
      ),
      'No pudimos guardar la categoría. Intentá nuevamente.',
    );
  });
}
