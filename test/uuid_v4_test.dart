import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_app/core/utils/uuid_v4.dart';

void main() {
  test('genera UUID v4 válidos y no repetidos', () {
    final values = List<String>.generate(200, (_) => uuidV4());

    expect(values.toSet(), hasLength(values.length));
    expect(values.every(isUuid), isTrue);
    expect(values.every((value) => value[14] == '4'), isTrue);
    expect(
      values.every((value) => const {'8', '9', 'a', 'b'}.contains(value[19])),
      isTrue,
    );
  });

  test('conserva un UUID existente y reemplaza identificadores temporales', () {
    const existing = '123e4567-e89b-42d3-a456-426614174000';

    expect(uuidOrNew(existing), existing);
    expect(uuidOrNew('temporary-id'), isNot('temporary-id'));
  });
}
