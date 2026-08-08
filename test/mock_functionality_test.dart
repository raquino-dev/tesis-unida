import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_app/features/accounts/data/mock_account_repository.dart';
import 'package:finanzas_app/features/family/data/mock_family_repository.dart';
import 'package:finanzas_app/features/family/domain/family_entity.dart';
import 'package:finanzas_app/features/savings_goals/data/mock_savings_goal_repository.dart';
import 'package:finanzas_app/features/savings_goals/domain/savings_goal_entity.dart';
import 'package:finanzas_app/features/security/data/mock_security_repository.dart';

void main() {
  group('Mock security flows', () {
    test('creates tokens and validates OTP', () async {
      final repository = MockSecurityRepository();
      final session = await repository.createSession(trustedDevice: true);
      expect(session.accessToken, startsWith('mock.jwt.access.'));
      expect(session.refreshToken, isNotEmpty);

      final challenge = await repository.requestOtp('Prueba');
      expect(await repository.validateOtp(challenge.id, '000000'), isNull);
      expect(
        await repository.validateOtp(challenge.id, challenge.demoCode!),
        isNotNull,
      );
      expect(await repository.getEvents(), isNotEmpty);
    });
  });

  group('Mock savings goals', () {
    test('creates a shared goal and records contributions', () async {
      final repository = MockSavingsGoalRepository();
      final created = await repository.createGoal(
        SavingsGoalEntity(
          id: '',
          name: 'Casa familiar',
          targetAmount: 10000000,
          savedAmount: 0,
          targetDate: DateTime(2027),
          scope: SavingsGoalScope.family,
        ),
      );
      final updated = await repository.contribute(
        created.id,
        500000,
        accountId: 'acc_test',
      );
      expect(updated.savedAmount, 500000);
      expect(updated.scope, SavingsGoalScope.family);
    });
  });

  group('Mock family treasury', () {
    test('maintains contribution and withdrawal traceability', () async {
      final repository = MockFamilyRepository(MockAccountRepository());
      final group = await repository.createFamilyGroup('Familia de prueba');
      expect(group.members.single.role, FamilyRole.owner);

      await repository.addTreasuryOperation(
        TreasuryOperationEntity(
          id: '',
          type: TreasuryOperationType.contribution,
          amount: 1000000,
          description: 'Aporte inicial',
          memberName: 'Propietario',
          date: DateTime.now(),
        ),
      );
      await repository.addTreasuryOperation(
        TreasuryOperationEntity(
          id: '',
          type: TreasuryOperationType.withdrawal,
          amount: 250000,
          description: 'Compra familiar',
          memberName: 'Propietario',
          date: DateTime.now(),
          otpVerificationId: 'otp_verified',
        ),
      );
      expect(await repository.getTreasuryOperations(), hasLength(2));
    });

    test('rejects withdrawals by a regular member', () async {
      final repository = MockFamilyRepository(MockAccountRepository());
      await repository.createFamilyGroup('Familia de prueba');
      await repository.addTreasuryOperation(
        TreasuryOperationEntity(
          id: '',
          type: TreasuryOperationType.contribution,
          amount: 1000000,
          description: 'Aporte inicial',
          memberName: 'Integrante',
          date: DateTime.now(),
        ),
      );
      await expectLater(
        repository.addTreasuryOperation(
          TreasuryOperationEntity(
            id: '',
            type: TreasuryOperationType.withdrawal,
            amount: 100000,
            description: 'Retiro no autorizado',
            memberName: 'Integrante',
            actorRole: FamilyRole.member,
            otpVerificationId: 'otp_verified',
            date: DateTime.now(),
          ),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
