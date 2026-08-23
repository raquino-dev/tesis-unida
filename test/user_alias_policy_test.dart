import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_app/features/auth/domain/user_alias_policy.dart';

void main() {
  group('UserAliasPolicy', () {
    test('acepta alias válido y quita el arroba inicial', () {
      expect(UserAliasPolicy.validate('@Rodrigo001'), isNull);
      expect(UserAliasPolicy.normalize('@Rodrigo001'), 'Rodrigo001');
    });

    test('rechaza espacios, símbolos y alias que empiezan con números', () {
      expect(UserAliasPolicy.validate('2rodrigo'), isNotNull);
      expect(UserAliasPolicy.validate('rodrigo.aquino'), isNotNull);
      expect(UserAliasPolicy.validate('ro drigo'), isNotNull);
      expect(UserAliasPolicy.validate('rodri@go'), isNotNull);
    });
  });
}
