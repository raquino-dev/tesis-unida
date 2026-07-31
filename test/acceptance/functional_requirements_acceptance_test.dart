import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finanzas_app/features/accounts/data/mock_account_repository.dart';
import 'package:finanzas_app/features/accounts/domain/account_entity.dart';
import 'package:finanzas_app/features/alerts/data/mock_alert_repository.dart';
import 'package:finanzas_app/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:finanzas_app/features/budgets/data/mock_budget_repository.dart';
import 'package:finanzas_app/features/budgets/domain/budget_entity.dart';
import 'package:finanzas_app/features/categories/data/mock_category_repository.dart';
import 'package:finanzas_app/features/categories/domain/category_entity.dart';
import 'package:finanzas_app/features/export/data/mock_export_repository.dart';
import 'package:finanzas_app/features/export/domain/export_entity.dart';
import 'package:finanzas_app/features/family/data/mock_family_repository.dart';
import 'package:finanzas_app/features/family/domain/family_entity.dart';
import 'package:finanzas_app/features/movements/data/mock_movement_repository.dart';
import 'package:finanzas_app/features/movements/domain/movement_entity.dart';
import 'package:finanzas_app/features/movements/presentation/viewmodels/movement_list_viewmodel.dart';
import 'package:finanzas_app/features/ocr/data/mock_ocr_repository.dart';
import 'package:finanzas_app/features/ocr/domain/ocr_repository.dart';
import 'package:finanzas_app/features/predictions/data/mock_prediction_repository.dart';
import 'package:finanzas_app/features/reports/data/mock_report_repository.dart';
import 'package:finanzas_app/features/reports/domain/report_entity.dart';
import 'package:finanzas_app/features/savings_goals/data/mock_savings_goal_repository.dart';
import 'package:finanzas_app/features/savings_goals/domain/savings_goal_entity.dart';
import 'package:finanzas_app/features/security/data/mock_security_repository.dart';
import 'package:finanzas_app/features/security/domain/security_entity.dart';
import 'package:finanzas_app/features/subscription/data/mock_subscription_repository.dart';
import 'package:finanzas_app/features/subscription/domain/subscription_entity.dart';
import 'package:finanzas_app/features/transfers/data/mock_transfer_repository.dart';

class _Fixture {
  final accounts = MockAccountRepository();
  final categories = MockCategoryRepository();
  late final family = MockFamilyRepository(accounts);
  late final movements = MockMovementRepository(categories, accounts);
  late final transfers = MockTransferRepository(accounts);

  Future<(AccountEntity, CategoryEntity)> references() async {
    final account = (await accounts.getAccounts()).first;
    final category = (await categories.getCategories()).first;
    return (account, category);
  }

  Future<MovementEntity> addPrivateMovement({
    MovementType type = MovementType.expense,
    double amount = 100000,
  }) async {
    final (account, category) = await references();
    return movements.addMovement(
      MovementEntity(
        id: '',
        type: type,
        amount: amount,
        date: DateTime.now(),
        categories: [category],
        description: 'Movimiento de aceptación',
        account: account,
      ),
    );
  }
}

void main() {
  group('Pruebas de aceptación RF-01 a RF-21', () {
    test(
      'RF-01 registro e inicio de sesión emiten una sesión protegida mock',
      () async {
        final fixture = _Fixture();
        final auth = MockAuthRepository(fixture.family);
        final security = MockSecurityRepository();
        final registered = await auth.register(
          name: 'Usuario piloto',
          email: 'piloto@demo.com',
          password: 'clave123',
          acceptsTerms: true,
        );
        final loggedIn = await auth.login(
          email: registered.email,
          password: 'clave123',
        );
        final session = await security.createSession(trustedDevice: true);
        expect(loggedIn.email, registered.email);
        expect(session.accessToken, startsWith('mock.jwt.access.'));
        expect(session.refreshToken, isNotEmpty);
      },
    );

    test(
      'RF-02 recuperación y cambio de contraseña completan sus flujos',
      () async {
        final auth = MockAuthRepository(_Fixture().family);
        await expectLater(
          auth.sendPasswordRecovery(email: 'piloto@demo.com'),
          completes,
        );
        await expectLater(
          auth.changePassword(
            currentPassword: 'actual123',
            newPassword: 'nueva123',
            otpVerificationId: 'verification_mock',
          ),
          completes,
        );
      },
    );

    test('RF-03 crear grupo asigna automáticamente al propietario', () async {
      final family = _Fixture().family;
      final group = await family.createFamilyGroup('Familia piloto');
      expect(group.members.single.role, FamilyRole.owner);
      expect(group.members.single.id, 'you');
    });

    test(
      'RF-04 administrador invita, excluye miembros y elimina el grupo',
      () async {
        final family = _Fixture().family;
        await family.createFamilyGroup('Familia piloto');
        final invitation = await family.createInvitation(
          email: 'invitado@demo.com',
          userIdentifier: 'USR-100',
          invitedName: 'Invitado',
          role: FamilyRole.member,
        );
        expect((await family.getFamilyGroup())!.members, hasLength(1));
        final withMember = await family.acceptInvitation(
          invitation.token ?? 'mock-token',
          invitation.code,
        );
        final member = withMember.members.firstWhere(
          (item) => item.id != 'you',
        );
        final withoutMember = await family.removeMember(member.id);
        expect(invitation.code, hasLength(6));
        expect(withoutMember.members, hasLength(1));
        await family.deleteFamilyGroup('otp-verification');
        expect(await family.getFamilyGroup(), isNull);
      },
    );

    test(
      'RF-05 registra ingresos/gastos privados y familiares por separado',
      () async {
        final fixture = _Fixture();
        await fixture.addPrivateMovement(
          type: MovementType.income,
          amount: 900000,
        );
        final group = await fixture.family.createFamilyGroup('Familia piloto');
        final account = (await fixture.accounts.getAccounts()).first;
        final category = (await fixture.categories.getCategories()).first;
        await fixture.family.addSharedAccount(account.id);
        await fixture.family.addFamilyMovement(
          FamilyMovementEntity(
            id: '',
            type: FamilyMovementType.expense,
            amount: 120000,
            date: DateTime.now(),
            category: category,
            account: account,
            description: 'Compra familiar',
            createdByMemberId: group.members.first.id,
            createdByMemberName: group.members.first.name,
          ),
        );
        expect(await fixture.movements.getMovements(), isNotEmpty);
        expect(await fixture.family.getFamilyMovements(), hasLength(1));
      },
    );

    test('RF-06 registra manualmente una transacción válida', () async {
      final fixture = _Fixture();
      final created = await fixture.addPrivateMovement(amount: 175000);
      expect(created.id, isNotEmpty);
      expect(created.description, 'Movimiento de aceptación');
    });

    test(
      'RF-07 procesa capturas de imagen y archivos PDF mediante OCR mock',
      () async {
        final ocr = MockOcrRepository();
        final image = await ocr.processReceipt(OcrSource.camera);
        final pdf = await ocr.processReceipt(OcrSource.pdf);
        expect(image.source, OcrSource.camera);
        expect(pdf.source, OcrSource.pdf);
        expect(pdf.documentReference, endsWith('.pdf'));
      },
    );

    test('RF-08 importa XML de comprobante electrónico SIFEN', () async {
      final result = await MockOcrRepository().processReceipt(OcrSource.xml);
      expect(result.source, OcrSource.xml);
      expect(result.documentReference, startsWith('CDC-DEMO'));
      expect(result.merchant, contains('SIFEN'));
    });

    test('RF-09 permite corregir y confirmar datos detectados', () async {
      final fixture = _Fixture();
      final detected = await MockOcrRepository().processReceipt(OcrSource.xml);
      final (account, category) = await fixture.references();
      final corrected = await fixture.movements.addMovement(
        MovementEntity(
          id: '',
          type: MovementType.expense,
          amount: detected.amount + 5000,
          date: detected.date,
          categories: [category],
          description: '${detected.merchant} corregido',
          account: account,
          hasAttachment: true,
          attachmentType: AttachmentType.xml,
          ocrStatus: detected.status,
        ),
      );
      expect(corrected.amount, detected.amount + 5000);
      expect(corrected.description, endsWith('corregido'));
    });

    test('RF-10 combina categorías predefinidas y personalizadas', () async {
      final repository = MockCategoryRepository();
      final predefined = await repository.getCategories();
      await repository.createCategory(
        const CategoryEntity(
          id: 'cat_piloto',
          name: 'Categoría piloto',
          icon: Icons.star_outline,
          color: Colors.blue,
          type: CategoryType.expense,
          inUse: false,
        ),
      );
      final updated = await repository.getCategories();
      expect(predefined, isNotEmpty);
      expect(updated.any((item) => item.id == 'cat_piloto'), isTrue);
    });

    test('RF-11 crea y sigue presupuestos privados y familiares', () async {
      final fixture = _Fixture();
      final category = (await fixture.categories.getCategories()).first;
      final privateBudgets = MockBudgetRepository(fixture.categories);
      final privateBudget = await privateBudgets.createBudget(
        BudgetEntity(
          id: '',
          name: 'Presupuesto piloto',
          amount: 1000000,
          spent: 200000,
          categories: [category],
        ),
      );
      await fixture.family.createFamilyGroup('Familia piloto');
      final familyBudget = await fixture.family.saveFamilyBudget(
        const FamilyBudgetEntity(
          id: '',
          categoryName: 'Alimentación',
          amount: 2000000,
          spent: 300000,
        ),
      );
      expect(privateBudget.progress, closeTo(0.2, 0.001));
      expect(familyBudget.progress, closeTo(0.15, 0.001));
    });

    test(
      'RF-12 crea metas de ahorro privadas y compartidas y recibe aportes',
      () async {
        final goals = MockSavingsGoalRepository();
        final shared = await goals.createGoal(
          SavingsGoalEntity(
            id: '',
            name: 'Meta familiar',
            targetAmount: 5000000,
            savedAmount: 0,
            targetDate: DateTime.now().add(const Duration(days: 180)),
            scope: SavingsGoalScope.family,
          ),
        );
        final updated = await goals.contribute(
          shared.id,
          750000,
          accountId: 'acc_test',
        );
        expect(updated.scope, SavingsGoalScope.family);
        expect(updated.savedAmount, 750000);
      },
    );

    test(
      'RF-13 caja compartida mantiene aportes, retiros y trazabilidad',
      () async {
        final family = _Fixture().family;
        await family.createFamilyGroup('Familia piloto');
        await family.addTreasuryOperation(
          TreasuryOperationEntity(
            id: '',
            type: TreasuryOperationType.contribution,
            amount: 1000000,
            description: 'Aporte',
            memberName: 'Propietario',
            date: DateTime.now(),
          ),
        );
        await family.addTreasuryOperation(
          TreasuryOperationEntity(
            id: '',
            type: TreasuryOperationType.withdrawal,
            amount: 250000,
            description: 'Retiro',
            memberName: 'Propietario',
            date: DateTime.now(),
            otpVerificationId: 'otp_verified',
          ),
        );
        final operations = await family.getTreasuryOperations();
        expect(
          operations.map((item) => item.type),
          containsAll([
            TreasuryOperationType.contribution,
            TreasuryOperationType.withdrawal,
          ]),
        );
      },
    );

    test(
      'RF-14 genera dashboard/reporte individual y resumen familiar',
      () async {
        final fixture = _Fixture();
        await fixture.addPrivateMovement();
        final report = await MockReportRepository(
          fixture.categories,
          fixture.movements,
        ).getReport(ReportRange.month);
        await fixture.family.createFamilyGroup('Familia piloto');
        final familyBudgets = await fixture.family.getFamilyBudgets();
        expect(report.totalExpense, greaterThan(0));
        expect(report.distribution, isNotEmpty);
        expect(familyBudgets, isNotEmpty);
      },
    );

    test('RF-15 exporta reportes locales válidos en PDF y Excel', () async {
      final fixture = _Fixture();
      final repository = MockExportRepository(
        fixture.movements,
        fixture.transfers,
      );
      final range = DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      );
      final pdf = await repository.requestExport(
        format: ExportFormat.pdf,
        range: range,
        filters: const MovementFilters(),
        filtersSummary: 'Aceptación',
      );
      final excel = await repository.requestExport(
        format: ExportFormat.excel,
        range: range,
        filters: const MovementFilters(),
        filtersSummary: 'Aceptación',
      );
      final pdfFile = File(pdf.artifactPath!);
      final excelFile = File(excel.artifactPath!);
      expect(await pdfFile.readAsString(), startsWith('%PDF-1.4'));
      expect(await excelFile.readAsString(), contains('<Workbook'));
      await pdfFile.delete();
      await excelFile.delete();
    });

    test(
      'RF-16 proyecta gasto mensual y por categoría desde el historial',
      () async {
        final fixture = _Fixture();
        final prediction = await MockPredictionRepository(
          fixture.movements,
        ).getPrediction();
        expect(prediction.projectedExpense, greaterThan(0));
        expect(prediction.categoryPredictions, isNotEmpty);
        expect(prediction.isPreliminary, isTrue);
        expect(prediction.historyMonths, lessThan(3));
      },
    );

    test('RF-17 emite alertas y recomendaciones comprensibles', () async {
      final fixture = _Fixture();
      final alerts = await MockAlertRepository(fixture.movements).getAlerts();
      expect(alerts, isNotEmpty);
      expect(alerts.first.message, isNotEmpty);
      expect(alerts.first.recommendation, isNotEmpty);
      expect(alerts.first.dataUsed, contains('movimientos'));
    });

    test('RF-18 habilita y ejecuta autenticación biométrica mock', () async {
      final security = MockSecurityRepository();
      await security.setBiometricsEnabled(true);
      expect(await security.isBiometricsEnabled(), isTrue);
      expect(await security.authenticateBiometrically(), isTrue);
    });

    test('RF-19 exige y valida OTP en acciones sensibles', () async {
      final security = MockSecurityRepository();
      final challenge = await security.requestOtp('Acción crítica');
      expect(await security.validateOtp(challenge.id, '000000'), isNull);
      expect(
        await security.validateOtp(challenge.id, challenge.demoCode!),
        isNotNull,
      );
    });

    test(
      'RF-20 registra eventos relevantes de seguridad y auditoría',
      () async {
        final security = MockSecurityRepository();
        await security.recordEvent(
          SecurityEventType.criticalAction,
          'Eliminación de grupo familiar',
        );
        final events = await security.getEvents();
        expect(events.single.type, SecurityEventType.criticalAction);
        expect(events.single.successful, isTrue);
      },
    );

    test('RF-21 diferencia funcionalidades Free y Premium', () async {
      final subscriptions = MockSubscriptionRepository();
      final free = await subscriptions.getSubscription();
      final premium = await subscriptions.purchase(PlanId.premiumMonthly);
      expect(free.allows(PremiumCapability.ocr), isFalse);
      expect(premium.allows(PremiumCapability.ocr), isTrue);
      expect(premium.allows(PremiumCapability.exports), isTrue);
    });
  });
}
