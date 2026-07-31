import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:finanzas_app/core/network/api_client.dart';
import 'package:finanzas_app/core/services/pilot_local_store.dart';
import 'package:finanzas_app/features/accounts/data/api_account_repository.dart';
import 'package:finanzas_app/features/auth/data/repositories/api_auth_repository.dart';
import 'package:finanzas_app/features/budgets/data/api_budget_repository.dart';
import 'package:finanzas_app/features/budgets/domain/budget_entity.dart';
import 'package:finanzas_app/features/categories/data/api_category_repository.dart';
import 'package:finanzas_app/features/credit_cards/data/api_credit_card_repository.dart';
import 'package:finanzas_app/features/dashboard/data/api_dashboard_repository.dart';
import 'package:finanzas_app/features/alerts/data/api_alert_repository.dart';
import 'package:finanzas_app/features/family/data/api_family_repository.dart';
import 'package:finanzas_app/features/family/domain/family_entity.dart';
import 'package:finanzas_app/features/export/data/api_export_repository.dart';
import 'package:finanzas_app/features/export/domain/export_entity.dart';
import 'package:finanzas_app/features/movements/data/api_movement_repository.dart';
import 'package:finanzas_app/features/movements/domain/movement_entity.dart';
import 'package:finanzas_app/features/movements/presentation/viewmodels/movement_list_viewmodel.dart';
import 'package:finanzas_app/features/ocr/data/api_ocr_repository.dart';
import 'package:finanzas_app/features/ocr/domain/ocr_repository.dart';
import 'package:finanzas_app/features/predictions/data/api_prediction_repository.dart';
import 'package:finanzas_app/features/recurring_movements/data/api_recurring_movement_repository.dart';
import 'package:finanzas_app/features/recurring_movements/domain/recurring_movement_entity.dart';
import 'package:finanzas_app/features/security/data/api_security_repository.dart';
import 'package:finanzas_app/features/reports/data/api_report_repository.dart';
import 'package:finanzas_app/features/reports/domain/report_entity.dart';
import 'package:finanzas_app/features/savings_goals/data/api_savings_goal_repository.dart';
import 'package:finanzas_app/features/score/data/api_score_repository.dart';
import 'package:finanzas_app/features/transfers/data/api_transfer_repository.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(PilotLocalStore.clearSession);

  test(
    'autentica y carga la vertical financiera con el contrato real',
    () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        switch ('${request.method} ${request.url.path}') {
          case 'POST /api/v1/sesiones':
            return _json(201, {
              'id': '01900000-0000-7000-8000-000000000001',
              'accessToken': 'access-token',
              'refreshToken': 'refresh-token',
            });
          case 'GET /api/v1/perfil':
            expect(request.headers['authorization'], 'Bearer access-token');
            return _json(200, {
              'id': '01900000-0000-7000-8000-000000000002',
              'correo': 'tesis@unida.edu.py',
              'nombre': 'Usuario Tesis',
              'moneda': 'PYG',
              'idioma': 'es',
              'ubicacion': 'Asunción',
            });
          case 'GET /api/v1/cuentas':
            return _json(200, {
              'elementos': [
                {
                  'id': '01900000-0000-7000-8000-000000000003',
                  'nombre': 'Efectivo',
                  'tipo': 'efectivo',
                  'saldoActual': 500000,
                  'incluidaEnTotal': true,
                  'version': 1,
                },
              ],
            });
          case 'GET /api/v1/categorias':
            return _json(200, {
              'elementos': [
                {
                  'id': '01900000-0000-7000-8000-000000000004',
                  'nombre': 'Alimentación',
                  'tipo': 'gasto',
                  'color': '#ff336699',
                  'enUso': true,
                  'version': 1,
                },
              ],
            });
          case 'GET /api/v1/movimientos':
            return _json(200, {
              'elementos': [
                {
                  'id': '01900000-0000-7000-8000-000000000005',
                  'cuentaId': '01900000-0000-7000-8000-000000000003',
                  'tipo': 'gasto',
                  'monto': 45000,
                  'descripcion': 'Supermercado',
                  'fecha': '2026-07-29',
                  'estado': 'confirmado',
                  'categoriaIds': ['01900000-0000-7000-8000-000000000004'],
                  'version': 1,
                },
              ],
            });
        }
        fail('Solicitud inesperada: ${request.method} ${request.url}');
      });
      final api = ApiClient(
        httpClient: client,
        baseUrl: 'http://localhost:8080/api/v1',
      );
      final auth = ApiAuthRepository(api);
      final accounts = ApiAccountRepository(api);
      final categories = ApiCategoryRepository(api);
      final movements = ApiMovementRepository(api, categories, accounts);

      final user = await auth.login(
        email: 'tesis@unida.edu.py',
        password: 'Segura-123456!',
      );
      final result = await movements.getMovements();

      expect(user.name, 'Usuario Tesis');
      expect(result.single.description, 'Supermercado');
      expect(result.single.account.name, 'Efectivo');
      expect(result.single.primaryCategory.name, 'Alimentación');
      expect(requests, hasLength(5));
    },
  );

  test('envía el ETag recibido al actualizar una cuenta', () async {
    String? ifMatch;
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return _json(200, {
          'elementos': [
            {
              'id': '01900000-0000-7000-8000-000000000003',
              'nombre': 'Efectivo',
              'tipo': 'efectivo',
              'saldoActual': 500000,
              'incluidaEnTotal': true,
              'version': 7,
            },
          ],
        });
      }
      ifMatch = request.headers['if-match'];
      return _json(200, {
        'id': '01900000-0000-7000-8000-000000000003',
        'nombre': 'Caja',
        'tipo': 'efectivo',
        'saldoActual': 500000,
        'incluidaEnTotal': true,
        'version': 8,
      });
    });
    final repository = ApiAccountRepository(
      ApiClient(httpClient: client, baseUrl: 'http://localhost:8080/api/v1'),
    );
    final account = (await repository.getAccounts()).single;

    await repository.updateAccount(account.copyWith(name: 'Caja'));

    expect(ifMatch, '"7"');
  });

  test('completa OTP, cambio de contraseña y gestión de sesiones', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      expect(request.headers['authorization'], 'Bearer access-token');
      switch ('${request.method} ${request.url.path}') {
        case 'POST /api/v1/desafios-otp':
          expect(jsonDecode(request.body)['motivo'], 'cambio-contrasena');
          return _json(201, {
            'id': '01900000-0000-7000-8000-000000000010',
            'destinoEnmascarado': 'te***@correo.com',
            'expiraEn': '2026-07-29T20:00:00Z',
            'intentosRestantes': 5,
          });
        case 'POST /api/v1/verificaciones-otp':
          return _json(201, {
            'id': '01900000-0000-7000-8000-000000000011',
            'valida': true,
            'expiraEn': '2026-07-29T20:10:00Z',
          });
        case 'PUT /api/v1/perfil/contrasena':
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(
            body['verificacionOtpId'],
            '01900000-0000-7000-8000-000000000011',
          );
          return http.Response('', 204);
        case 'GET /api/v1/sesiones':
          return _json(200, {
            'datos': [
              {
                'id': '01900000-0000-7000-8000-000000000012',
                'dispositivo': {
                  'id': '01900000-0000-7000-8000-000000000012',
                  'nombre': 'Pixel piloto',
                  'plataforma': 'android',
                },
                'emitidaEn': '2026-07-29T18:00:00Z',
                'expiraEn': '2026-08-28T18:00:00Z',
                'actual': false,
              },
            ],
            'paginacion': {'cursorSiguiente': null},
          });
        case 'DELETE /api/v1/sesiones/01900000-0000-7000-8000-000000000012':
          return http.Response('', 204);
      }
      fail('Solicitud inesperada: ${request.method} ${request.url}');
    });
    final api = ApiClient(
      httpClient: client,
      baseUrl: 'http://localhost:8080/api/v1',
    );
    await PilotLocalStore.saveApiSession(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      sessionId: '01900000-0000-7000-8000-000000000099',
    );
    final security = ApiSecurityRepository(api);
    final auth = ApiAuthRepository(api);

    final challenge = await security.requestOtp('Cambio de contraseña');
    final verificationId = await security.validateOtp(challenge.id, '123456');
    await auth.changePassword(
      currentPassword: 'Actual-123456!',
      newPassword: 'Nueva-123456!',
      otpVerificationId: verificationId!,
    );
    final sessions = await security.getActiveSessions();
    await security.revokeSession(sessions.single.id);

    expect(challenge.demoCode, isNull);
    expect(sessions.single.deviceName, 'Pixel piloto');
    expect(requests.map((request) => request.method), [
      'POST',
      'POST',
      'PUT',
      'GET',
      'DELETE',
    ]);
  });

  test(
    'integra tarjetas por alias, transferencias y recurrencias con ETag',
    () async {
      String? recurringIfMatch;
      String? transferIfMatch;
      final client = MockClient((request) async {
        switch ('${request.method} ${request.url.path}') {
          case 'GET /api/v1/cuentas':
            return _json(200, {
              'elementos': [
                {
                  'id': '01900000-0000-7000-8000-000000000021',
                  'nombre': 'Cuenta origen',
                  'tipo': 'cuenta-ahorro',
                  'saldoActual': 900000,
                  'incluidaEnTotal': true,
                  'version': 1,
                },
                {
                  'id': '01900000-0000-7000-8000-000000000022',
                  'nombre': 'Cuenta destino',
                  'tipo': 'cuenta-corriente',
                  'saldoActual': 100000,
                  'incluidaEnTotal': true,
                  'version': 1,
                },
              ],
            });
          case 'GET /api/v1/categorias':
            return _json(200, {
              'elementos': [
                {
                  'id': '01900000-0000-7000-8000-000000000023',
                  'nombre': 'Servicios',
                  'tipo': 'gasto',
                  'color': '#6868A6',
                  'enUso': true,
                  'version': 1,
                },
              ],
            });
          case 'GET /api/v1/tarjetas-credito':
            return _json(200, {
              'datos': [_cardJson()],
              'paginacion': {'cursorSiguiente': null},
            });
          case 'POST /api/v1/tarjetas-credito':
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['alias'], 'Compras del hogar');
            expect(body.containsKey('emisor'), isFalse);
            expect(body.containsKey('ultimosCuatro'), isFalse);
            return _json(201, _cardJson(version: 2));
          case 'POST /api/v1/transferencias':
            expect(request.headers['idempotency-key'], isNotEmpty);
            return _json(201, {
              'id': '01900000-0000-7000-8000-000000000025',
              'cuentaOrigen': {
                'id': '01900000-0000-7000-8000-000000000021',
                'nombre': 'Cuenta origen',
              },
              'cuentaDestino': {
                'id': '01900000-0000-7000-8000-000000000022',
                'nombre': 'Cuenta destino',
              },
              'monto': 150000,
              'fecha': '2026-07-30',
              'descripcion': 'Ahorro',
              'estado': 'confirmada',
              'creadoEn': '2026-07-30T12:00:00Z',
              'version': 2,
            });
          case 'DELETE /api/v1/transferencias/01900000-0000-7000-8000-000000000025':
            transferIfMatch = request.headers['if-match'];
            return http.Response('', 204);
          case 'GET /api/v1/movimientos-recurrentes':
            return _json(200, {
              'datos': [_recurringJson()],
              'paginacion': {
                'siguienteCursor': null,
                'hayMas': false,
                'limite': 20,
              },
            });
          case 'PATCH /api/v1/movimientos-recurrentes/01900000-0000-7000-8000-000000000026':
            recurringIfMatch = request.headers['if-match'];
            expect(jsonDecode(request.body), {'estado': 'pausada'});
            return _json(200, _recurringJson(status: 'pausada', version: 4));
        }
        fail('Solicitud inesperada: ${request.method} ${request.url}');
      });
      final api = ApiClient(
        httpClient: client,
        baseUrl: 'http://localhost:8080/api/v1',
      );
      final accounts = ApiAccountRepository(api);
      final categories = ApiCategoryRepository(api);
      final cards = ApiCreditCardRepository(api, accounts);
      final transfers = ApiTransferRepository(api, accounts);
      final recurring = ApiRecurringMovementRepository(
        api,
        categories,
        accounts,
      );

      final card = (await cards.getCreditCards()).single;
      final createdCard = await cards.createCreditCard(card);
      final transfer = await transfers.createTransfer(
        fromAccountId: '01900000-0000-7000-8000-000000000021',
        toAccountId: '01900000-0000-7000-8000-000000000022',
        amount: 150000,
        date: DateTime(2026, 7, 30),
        note: 'Ahorro',
      );
      await transfers.cancelTransfer(transfer);
      final schedule = (await recurring.getRecurringMovements()).single;
      final paused = await recurring.setStatus(
        schedule,
        RecurringStatus.paused,
      );

      expect(createdCard.alias, 'Compras del hogar');
      expect(transfer.toAccount.name, 'Cuenta destino');
      expect(transferIfMatch, '"2"');
      expect(paused.status, RecurringStatus.paused);
      expect(recurringIfMatch, '"3"');
    },
  );

  test('integra presupuestos y metas de ahorro con aportes reales', () async {
    String? budgetIfMatch;
    String? goalIfMatch;
    final client = MockClient((request) async {
      switch ('${request.method} ${request.url.path}') {
        case 'GET /api/v1/categorias':
          return _json(200, {
            'elementos': [
              {
                'id': '01900000-0000-7000-8000-000000000031',
                'nombre': 'Alimentación',
                'tipo': 'gasto',
                'color': '#6868A6',
                'enUso': true,
                'version': 1,
              },
            ],
          });
        case 'GET /api/v1/resumen-presupuestario':
          return _json(200, {
            'total': 2000000,
            'gastado': 500000,
            'disponible': 1500000,
            'progreso': 0.25,
            'presupuestos': [_budgetJson()],
          });
        case 'GET /api/v1/presupuestos':
          return _json(200, {
            'datos': [_budgetJson()],
            'paginacion': {
              'siguienteCursor': null,
              'hayMas': false,
              'limite': 20,
            },
          });
        case 'PATCH /api/v1/presupuestos/01900000-0000-7000-8000-000000000032':
          budgetIfMatch = request.headers['if-match'];
          expect(jsonDecode(request.body)['periodo'], 'semanal');
          return _json(
            200,
            _budgetJson(version: 2, amount: 2500000, period: 'semanal'),
          );
        case 'GET /api/v1/metas-ahorro':
          return _json(200, {
            'datos': [_goalJson()],
            'paginacion': {
              'siguienteCursor': null,
              'hayMas': false,
              'limite': 20,
            },
          });
        case 'POST /api/v1/metas-ahorro':
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['cuentaId'], '01900000-0000-7000-8000-000000000034');
          return _json(
            201,
            _goalJson(
              id: '01900000-0000-7000-8000-000000000037',
              saved: 0,
              version: 2,
            ),
          );
        case 'POST /api/v1/metas-ahorro/01900000-0000-7000-8000-000000000033/aportes':
          expect(request.headers['idempotency-key'], isNotEmpty);
          expect(
            jsonDecode(request.body)['cuentaOrigenId'],
            '01900000-0000-7000-8000-000000000035',
          );
          return _json(201, {
            'id': '01900000-0000-7000-8000-000000000036',
            'metaAhorroId': '01900000-0000-7000-8000-000000000033',
            'monto': 500000,
            'aportadoPor': {
              'id': '01900000-0000-7000-8000-000000000001',
              'nombre': 'Usuario',
            },
            'fecha': '2026-07-30',
            'creadoEn': '2026-07-30T12:00:00Z',
            'saldoMeta': 1500000,
          });
        case 'GET /api/v1/metas-ahorro/01900000-0000-7000-8000-000000000033':
          return _json(200, _goalJson(saved: 1500000, version: 3));
        case 'DELETE /api/v1/metas-ahorro/01900000-0000-7000-8000-000000000037':
          goalIfMatch = request.headers['if-match'];
          return http.Response('', 204);
      }
      fail('Solicitud inesperada: ${request.method} ${request.url}');
    });
    final api = ApiClient(
      httpClient: client,
      baseUrl: 'http://localhost:8080/api/v1',
    );
    final budgets = ApiBudgetRepository(api, ApiCategoryRepository(api));
    final goals = ApiSavingsGoalRepository(api);

    final overall = await budgets.getOverallBudget();
    final budget = (await budgets.getCategoryBudgets()).single;
    final updatedBudget = await budgets.updateBudget(
      budget.copyWith(amount: 2500000, period: BudgetPeriod.weekly),
    );
    final goal = (await goals.getGoals()).single;
    final createdGoal = await goals.createGoal(goal);
    await goals.deleteGoal(createdGoal.id);
    final contributed = await goals.contribute(
      goal.id,
      500000,
      accountId: '01900000-0000-7000-8000-000000000035',
    );

    expect(overall.remaining, 1500000);
    expect(updatedBudget.amount, 2500000);
    expect(budgetIfMatch, '"1"');
    expect(createdGoal.accountName, 'Ahorro meta');
    expect(contributed.savedAmount, 1500000);
    expect(goalIfMatch, '"2"');
  });

  test('integra grupo, invitación, caja y presupuesto familiar', () async {
    String? invitationIdempotencyKey;
    String? treasuryIdempotencyKey;
    String? deletionIfMatch;
    final client = MockClient((request) async {
      switch ('${request.method} ${request.url.path}') {
        case 'GET /api/v1/grupos-familiares':
          return _json(200, {
            'datos': [
              {
                'id': '01900000-0000-7000-8000-000000000040',
                'nombre': 'Familia Aquino',
                'miRol': 'propietario',
                'cantidadIntegrantes': 1,
                'cantidadCuentasCompartidas': 1,
                'creadoEn': '2026-07-30T12:00:00Z',
                'version': 4,
              },
            ],
            'paginacion': {'cursorSiguiente': null},
          });
        case 'GET /api/v1/grupos-familiares/01900000-0000-7000-8000-000000000040/integrantes':
          return _json(200, {
            'datos': [
              {
                'id': '01900000-0000-7000-8000-000000000041',
                'usuario': {
                  'id': '01900000-0000-7000-8000-000000000001',
                  'nombre': 'Elvio Aquino',
                  'correo': 'elvio@example.com',
                },
                'rol': 'propietario',
                'incorporadoEn': '2026-07-30T12:00:00Z',
                'version': 1,
              },
            ],
            'paginacion': {'cursorSiguiente': null},
          });
        case 'GET /api/v1/grupos-familiares/01900000-0000-7000-8000-000000000040/cuentas-compartidas':
          return _json(200, {
            'datos': [
              {
                'grupoFamiliarId': '01900000-0000-7000-8000-000000000040',
                'cuenta': {
                  'id': '01900000-0000-7000-8000-000000000042',
                  'nombre': 'Cuenta hogar',
                  'tipo': 'cuenta-ahorro',
                  'moneda': 'PYG',
                },
                'compartidaPor': {
                  'id': '01900000-0000-7000-8000-000000000001',
                  'nombre': 'Elvio Aquino',
                },
                'compartidaEn': '2026-07-30T12:00:00Z',
                'version': 2,
              },
            ],
            'paginacion': {'cursorSiguiente': null},
          });
        case 'GET /api/v1/grupos-familiares/01900000-0000-7000-8000-000000000040/categorias':
          return _json(200, {
            'datos': [
              {
                'id': '01900000-0000-7000-8000-000000000043',
                'grupoFamiliarId': '01900000-0000-7000-8000-000000000040',
                'nombre': 'Alimentación',
                'tipo': 'gasto',
                'icono': 'restaurant',
                'color': '#F59E0B',
                'version': 1,
              },
            ],
            'paginacion': {'cursorSiguiente': null},
          });
        case 'POST /api/v1/grupos-familiares/01900000-0000-7000-8000-000000000040/invitaciones':
          invitationIdempotencyKey = request.headers['idempotency-key'];
          return http.Response(
            jsonEncode({
              'id': '01900000-0000-7000-8000-000000000044',
              'grupoFamiliarId': '01900000-0000-7000-8000-000000000040',
              'correo': 'familiar@example.com',
              'usuarioDestino': null,
              'rol': 'integrante',
              'estado': 'pendiente',
              'expiraEn': '2026-08-06T12:00:00Z',
              'version': 1,
              'codigo': '123456',
            }),
            201,
            headers: {
              'content-type': 'application/json',
              'location':
                  '/api/v1/invitaciones-familiares/token-familiar-seguro',
            },
          );
        case 'POST /api/v1/grupos-familiares/01900000-0000-7000-8000-000000000040/operaciones-caja':
          treasuryIdempotencyKey = request.headers['idempotency-key'];
          return _json(201, {
            'id': '01900000-0000-7000-8000-000000000045',
            'tipo': 'aporte',
            'monto': 300000,
            'descripcion': 'Aporte mensual',
            'realizadoPor': {
              'id': '01900000-0000-7000-8000-000000000001',
              'nombre': 'Elvio Aquino',
            },
            'creadoEn': '2026-07-30T13:00:00Z',
            'saldoAnterior': 0,
            'saldoPosterior': 300000,
          });
        case 'POST /api/v1/grupos-familiares/01900000-0000-7000-8000-000000000040/presupuestos':
          return _json(201, {
            'id': '01900000-0000-7000-8000-000000000046',
            'ambito': 'familiar',
            'nombre': 'Alimentación',
            'monto': 2500000,
            'gastado': 0,
            'disponible': 2500000,
            'progreso': 0,
            'estado': 'activo',
            'salud': 'saludable',
            'periodo': 'mensual',
            'categorias': [
              {
                'id': '01900000-0000-7000-8000-000000000043',
                'nombre': 'Alimentación',
              },
            ],
            'version': 1,
          });
        case 'POST /api/v1/grupos-familiares/01900000-0000-7000-8000-000000000040/eliminaciones':
          deletionIfMatch = request.headers['if-match'];
          return _json(202, {
            'id': '01900000-0000-7000-8000-000000000047',
            'estado': 'pendiente',
            'creadoEn': '2026-07-30T14:00:00Z',
            'completadoEn': null,
            'errorCodigo': null,
            'urlEstado':
                '/api/v1/grupos-familiares/01900000-0000-7000-8000-000000000040/eliminaciones/01900000-0000-7000-8000-000000000047',
            'version': 1,
          });
      }
      fail('Solicitud inesperada: ${request.method} ${request.url}');
    });
    final family = ApiFamilyRepository(
      ApiClient(httpClient: client, baseUrl: 'http://localhost:8080/api/v1'),
    );

    final group = await family.getFamilyGroup();
    final categories = await family.getFamilyCategories();
    final invitation = await family.createInvitation(
      email: 'familiar@example.com',
      userIdentifier: '',
    );
    final operation = await family.addTreasuryOperation(
      TreasuryOperationEntity(
        id: '',
        type: TreasuryOperationType.contribution,
        amount: 300000,
        description: 'Aporte mensual',
        memberName: 'Elvio Aquino',
        date: DateTime(2026, 7, 30),
        accountId: '01900000-0000-7000-8000-000000000042',
      ),
    );
    final budget = await family.saveFamilyBudget(
      FamilyBudgetEntity(
        id: '',
        categoryName: categories.single.name,
        categoryId: categories.single.id,
        amount: 2500000,
        spent: 0,
      ),
    );
    await family.deleteFamilyGroup('01900000-0000-7000-8000-000000000048');

    expect(group?.currentRole, FamilyRole.owner);
    expect(group?.sharedAccounts.single.name, 'Cuenta hogar');
    expect(invitation.token, 'token-familiar-seguro');
    expect(operation.amount, 300000);
    expect(budget.categoryId, categories.single.id);
    expect(invitationIdempotencyKey, isNotEmpty);
    expect(treasuryIdempotencyKey, isNotEmpty);
    expect(deletionIfMatch, '"4"');
  });

  test(
    'carga SIFEN, corrige datos, vincula movimiento y descarga exportación',
    () async {
      const documentId = '01900000-0000-7000-8000-000000000050';
      const processingId = '01900000-0000-7000-8000-000000000051';
      const accountId = '01900000-0000-7000-8000-000000000052';
      const categoryId = '01900000-0000-7000-8000-000000000053';
      const exportId = '01900000-0000-7000-8000-000000000054';
      final xmlBytes = utf8.encode(
        '<DE Id="CDC-TEST"><dNomEmi>Comercio SIFEN</dNomEmi>'
        '<dTotGralOpe>385000</dTotGralOpe></DE>',
      );
      final xml = File('${Directory.systemTemp.path}/sifen_contract_test.xml');
      await xml.writeAsBytes(xmlBytes);
      String? correctionIfMatch;
      String? movementDocumentId;
      String? exportIdempotency;
      final client = MockClient((request) async {
        switch ('${request.method} ${request.url.path}') {
          case 'POST /api/v1/documentos-financieros':
            expect(
              request.headers['x-content-sha256'],
              sha256.convert(xmlBytes).toString(),
            );
            expect(request.headers['idempotency-key'], isNotEmpty);
            expect(
              request.headers['content-type'],
              startsWith('multipart/form-data; boundary='),
            );
            expect(request.body, contains('xml-sifen'));
            return _json(202, {
              'id': documentId,
              'nombreOriginal': 'sifen_contract_test.xml',
              'tipo': 'xml-sifen',
              'mimeType': 'application/xml',
              'tamanoBytes': xmlBytes.length,
              'sha256': sha256.convert(xmlBytes).toString(),
              'estadoArchivo': 'disponible',
              'estadoProcesamiento': 'pendiente',
              'procesamientoId': processingId,
              'creadoEn': '2026-07-30T15:00:00Z',
              'version': 1,
            });
          case 'GET /api/v1/procesamientos-documentales/$processingId':
            return _json(200, {
              'id': processingId,
              'documentoId': documentId,
              'tipo': 'sifen',
              'estado': 'completado',
              'confianza': 0.95,
              'datosDetectados': {
                'monto': 385000,
                'fecha': '2026-07-30',
                'comercio': 'Comercio SIFEN',
                'categoriaSugeridaId': null,
                'cdcSifen': 'CDC-TEST',
              },
              'advertencias': <String>[],
              'iniciadoEn': '2026-07-30T15:00:01Z',
              'finalizadoEn': '2026-07-30T15:00:02Z',
              'version': 2,
            });
          case 'PATCH /api/v1/procesamientos-documentales/$processingId':
            correctionIfMatch = request.headers['if-match'];
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['datosDetectados']['categoriaSugeridaId'], categoryId);
            return _json(200, {
              'id': processingId,
              'documentoId': documentId,
              'tipo': 'sifen',
              'estado': 'completado',
              'confianza': 0.95,
              'datosDetectados': body['datosDetectados'],
              'advertencias': <String>[],
              'iniciadoEn': '2026-07-30T15:00:01Z',
              'finalizadoEn': '2026-07-30T15:00:02Z',
              'version': 3,
            });
          case 'GET /api/v1/cuentas':
            return _json(200, {
              'elementos': [
                {
                  'id': accountId,
                  'nombre': 'Cuenta principal',
                  'tipo': 'cuenta-ahorro',
                  'saldoActual': 1000000,
                  'incluidaEnTotal': true,
                  'version': 1,
                },
              ],
            });
          case 'GET /api/v1/categorias':
            return _json(200, {
              'elementos': [
                {
                  'id': categoryId,
                  'nombre': 'Compras',
                  'tipo': 'gasto',
                  'color': '#F59E0B',
                  'enUso': true,
                  'version': 1,
                },
              ],
            });
          case 'POST /api/v1/movimientos':
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            movementDocumentId = body['documentoId'] as String?;
            return _json(201, {
              'id': '01900000-0000-7000-8000-000000000055',
              'cuentaId': accountId,
              'tipo': 'gasto',
              'monto': 385000,
              'descripcion': 'Comercio SIFEN',
              'fecha': '2026-07-30',
              'estado': 'confirmado',
              'categoriaIds': [categoryId],
              'documentoId': documentId,
              'movimientoRecurrenteId': null,
              'version': 1,
            });
          case 'POST /api/v1/exportaciones':
            exportIdempotency = request.headers['idempotency-key'];
            return _json(202, _exportJson(exportId, estado: 'pendiente'));
          case 'GET /api/v1/exportaciones/$exportId':
            return _json(200, _exportJson(exportId, estado: 'completado'));
          case 'POST /api/v1/exportaciones/$exportId/descargas':
            return _json(201, {
              'url': 'http://localhost:8080/api/v1/descargas/$exportId.pdf',
              'expiraEn': '2026-07-30T16:00:00Z',
            });
          case 'GET /api/v1/descargas/$exportId.pdf':
            return http.Response.bytes(
              utf8.encode('%PDF-1.4 contract test'),
              200,
              headers: {'content-type': 'application/octet-stream'},
            );
        }
        fail('Solicitud inesperada: ${request.method} ${request.url}');
      });
      final api = ApiClient(
        httpClient: client,
        baseUrl: 'http://localhost:8080/api/v1',
      );
      final ocr = ApiOcrRepository(api);
      final accountRepository = ApiAccountRepository(api);
      final categoryRepository = ApiCategoryRepository(api);
      final movements = ApiMovementRepository(
        api,
        categoryRepository,
        accountRepository,
      );
      final exports = ApiExportRepository(api);

      final detected = await ocr.processReceipt(
        OcrSource.xml,
        documentPath: xml.path,
        documentName: xml.uri.pathSegments.last,
      );
      final corrected = await ocr.correctReceipt(
        detected,
        amount: detected.amount,
        date: detected.date,
        merchant: detected.merchant,
        categoryId: categoryId,
      );
      final account = (await accountRepository.getAccounts()).single;
      final category = (await categoryRepository.getCategories()).single;
      await movements.addMovement(
        MovementEntity(
          id: '',
          type: MovementType.expense,
          amount: corrected.amount,
          date: corrected.date,
          categories: [category],
          description: corrected.merchant,
          account: account,
          hasAttachment: true,
          attachmentType: AttachmentType.xml,
          ocrStatus: corrected.status,
          documentId: corrected.documentId,
        ),
      );
      final exported = await exports.requestExport(
        format: ExportFormat.pdf,
        range: DateTimeRange(
          start: DateTime(2026, 7, 1),
          end: DateTime(2026, 7, 30),
        ),
        filters: const MovementFilters(ocrFilter: OcrFilter.withOcr),
        filtersSummary: 'Solo con OCR',
      );

      expect(detected.documentReference, 'CDC-TEST');
      expect(correctionIfMatch, '"2"');
      expect(movementDocumentId, documentId);
      expect(exportIdempotency, isNotEmpty);
      expect(
        await File(exported.artifactPath!).readAsString(),
        startsWith('%PDF'),
      );
    },
  );

  test('integra dashboard, reportes, predicción, alertas y salud', () async {
    const alertId = '01900000-0000-7000-8000-000000000060';
    final alertIfMatches = <String?>[];
    final client = MockClient((request) async {
      switch ('${request.method} ${request.url.path}') {
        case 'GET /api/v1/perfil':
          return _json(200, {
            'id': '01900000-0000-7000-8000-000000000001',
            'correo': 'elvio@example.com',
            'nombre': 'Elvio Aquino',
            'moneda': 'PYG',
            'idioma': 'es',
            'ubicacion': 'Asunción',
          });
        case 'GET /api/v1/categorias':
          return _json(200, {
            'elementos': [
              {
                'id': '01900000-0000-7000-8000-000000000061',
                'nombre': 'Alimentación',
                'tipo': 'gasto',
                'color': '#F59E0B',
                'enUso': true,
                'version': 1,
              },
            ],
          });
        case 'GET /api/v1/tableros-financieros':
          expect(request.url.queryParameters['ambito'], 'privado');
          return _json(200, _dashboardJson());
        case 'GET /api/v1/reportes-financieros':
          expect(request.url.queryParameters['rango'], 'mes');
          return _json(200, _reportJson());
        case 'GET /api/v1/proyecciones-gastos':
          expect(request.url.queryParameters['periodo'], 'mensual');
          return _json(200, _predictionJson());
        case 'GET /api/v1/alertas-financieras':
          return _json(200, {
            'datos': [_alertJson(alertId)],
            'paginacion': {
              'siguienteCursor': null,
              'hayMas': false,
              'limite': 20,
            },
          });
        case 'GET /api/v1/alertas-financieras/$alertId':
          return _json(200, _alertJson(alertId));
        case 'PATCH /api/v1/alertas-financieras/$alertId':
          alertIfMatches.add(request.headers['if-match']);
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final archived = body['archivada'] == true;
          return _json(
            200,
            _alertJson(alertId, read: true, version: archived ? 3 : 2),
          );
        case 'GET /api/v1/score-financiero':
          return _json(200, _scoreJson());
      }
      fail('Solicitud inesperada: ${request.method} ${request.url}');
    });
    final api = ApiClient(
      httpClient: client,
      baseUrl: 'http://localhost:8080/api/v1',
    );
    final categories = ApiCategoryRepository(api);
    final dashboard = ApiDashboardRepository(
      api,
      ApiAuthRepository(api),
      categories,
    );
    final reports = ApiReportRepository(api, categories);
    final predictions = ApiPredictionRepository(api);
    final alerts = ApiAlertRepository(api);
    final scores = ApiScoreRepository(api);

    final summary = await dashboard.getSummary();
    final report = await reports.getReport(ReportRange.month);
    final prediction = await predictions.getPrediction();
    final listedAlert = (await alerts.getAlerts()).single;
    final readAlert = await alerts.getAlertById(listedAlert.id);
    await alerts.archive(listedAlert.id);
    final score = await scores.getScore();

    expect(summary.userName, 'Elvio Aquino');
    expect(summary.topCategories.single.category.name, 'Alimentación');
    expect(report.insights.single, contains('balance'));
    expect(prediction.modelVersion, 'gastos-v1');
    expect(readAlert.isRead, isTrue);
    expect(alertIfMatches, ['"1"', '"2"']);
    expect(score.score, 78);
    expect(score.algorithmVersion, 'score-v1');
  });
}

Map<String, dynamic> _cardJson({int version = 1}) => {
  'id': '01900000-0000-7000-8000-000000000024',
  'alias': 'Compras del hogar',
  'cuentaPago': {
    'id': '01900000-0000-7000-8000-000000000021',
    'nombre': 'Cuenta origen',
    'tipo': 'cuenta-ahorro',
  },
  'diaCierre': 20,
  'diaVencimiento': 5,
  'limiteCredito': 15000000,
  'saldoUtilizado': 4200000,
  'creditoDisponible': 10800000,
  'moneda': 'PYG',
  'color': '#6868A6',
  'version': version,
};

Map<String, dynamic> _recurringJson({
  String status = 'activa',
  int version = 3,
}) => {
  'id': '01900000-0000-7000-8000-000000000026',
  'tipo': 'gasto',
  'monto': 180000,
  'categorias': [
    {'id': '01900000-0000-7000-8000-000000000023', 'nombre': 'Servicios'},
  ],
  'cuenta': {
    'id': '01900000-0000-7000-8000-000000000021',
    'nombre': 'Cuenta origen',
  },
  'descripcion': 'Internet',
  'fechaInicio': '2026-07-01',
  'fechaFin': null,
  'frecuencia': 'mensual',
  'cantidadOcurrencias': null,
  'ocurrenciasCompletadas': 1,
  'proximaEjecucion': '2026-08-01',
  'estado': status,
  'version': version,
};

Map<String, dynamic> _budgetJson({
  int version = 1,
  int amount = 2000000,
  String period = 'mensual',
}) => {
  'id': '01900000-0000-7000-8000-000000000032',
  'ambito': 'privado',
  'nombre': 'Alimentación mensual',
  'monto': amount,
  'gastado': 500000,
  'disponible': amount - 500000,
  'progreso': 0.25,
  'estado': 'activo',
  'salud': 'saludable',
  'periodo': period,
  'categorias': [
    {'id': '01900000-0000-7000-8000-000000000031', 'nombre': 'Alimentación'},
  ],
  'version': version,
};

Map<String, dynamic> _goalJson({
  String id = '01900000-0000-7000-8000-000000000033',
  int version = 1,
  int saved = 1000000,
}) => {
  'id': id,
  'ambito': 'privado',
  'grupoFamiliarId': null,
  'nombre': 'Fondo de emergencia',
  'montoObjetivo': 10000000,
  'montoAhorrado': saved,
  'montoRestante': 10000000 - saved,
  'progreso': saved / 10000000,
  'fechaObjetivo': '2027-07-30',
  'cuenta': {
    'id': '01900000-0000-7000-8000-000000000034',
    'nombre': 'Ahorro meta',
  },
  'version': version,
};

Map<String, dynamic> _exportJson(String id, {required String estado}) => {
  'id': id,
  'formato': 'pdf',
  'estado': estado,
  'creadoEn': '2026-07-30T15:10:00Z',
  'finalizadoEn': '2026-07-30T15:10:02Z',
  'cantidadMovimientos': estado == 'completado' ? 1 : 0,
  'totales': {
    'ingresos': 0,
    'gastos': estado == 'completado' ? 385000 : 0,
    'transferido': 0,
  },
  'expiraEn': '2026-08-06T15:10:02Z',
  'version': estado == 'completado' ? 3 : 1,
};

Map<String, dynamic> _dashboardJson() => {
  'ambito': 'privado',
  'periodo': {'desde': '2026-07-01', 'hasta': '2026-07-31'},
  'ingresos': 7900000,
  'gastos': 1383000,
  'balance': 6517000,
  'presupuestoTotal': 40500000,
  'presupuestoDisponible': 39117000,
  'scoreFinanciero': 78,
  'categoriasPrincipales': [
    {
      'categoriaId': '01900000-0000-7000-8000-000000000061',
      'nombre': 'Alimentación',
      'monto': 327000,
      'porcentaje': 0.2364,
    },
  ],
  'proximosRecurrentes': [
    {'nombre': 'Internet', 'monto': 180000, 'fecha': '2026-08-01'},
  ],
  'alertasDestacadas': ['Revisá tu presupuesto de alimentación'],
};

Map<String, dynamic> _reportJson() => {
  'ambito': 'privado',
  'rango': 'mes',
  'desde': '2026-07-01',
  'hasta': '2026-07-31',
  'ingresos': 7900000,
  'gastos': 1383000,
  'balance': 6517000,
  'distribucion': _dashboardJson()['categoriasPrincipales'],
  'tendencia': [
    {'periodo': '2026-07', 'ingresos': 7900000, 'gastos': 1383000},
  ],
  'observaciones': ['El período cerró con balance no negativo.'],
};

Map<String, dynamic> _predictionJson() => {
  'ambito': 'privado',
  'mesesHistorial': 2,
  'preliminar': true,
  'gastoProyectado': 3850000,
  'balanceProyectado': 4050000,
  'categoriaMayorCrecimiento': 'Transporte',
  'nivelRiesgo': 'bajo',
  'versionModelo': 'gastos-v1',
  'periodo': {'desde': '2026-07-01', 'hasta': '2026-07-31'},
  'categorias': [
    {'nombre': 'Transporte', 'montoProyectado': 620000, 'variacion': 0.28},
  ],
  'historial': [
    {'periodo': '2026-06', 'proyectado': 3600000, 'real': 3550000},
  ],
  'generadoEn': '2026-07-30T16:00:00Z',
};

Map<String, dynamic> _alertJson(
  String id, {
  bool read = false,
  int version = 1,
}) => {
  'id': id,
  'titulo': 'Gastos superiores a ingresos',
  'mensaje': 'Los gastos confirmados superan a los ingresos.',
  'nivel': 'advertencia',
  'fecha': '2026-07-30T16:00:00Z',
  'queOcurrio': 'El balance mensual es negativo.',
  'datosUtilizados': 'Movimientos confirmados.',
  'impacto': 'Menor capacidad de ahorro.',
  'recomendacion': 'Revisá gastos no esenciales.',
  'leida': read,
  'version': version,
};

Map<String, dynamic> _scoreJson() => {
  'score': 78,
  'estado': 'saludable',
  'versionAlgoritmo': 'score-v1',
  'periodo': {'desde': '2026-05-01', 'hasta': '2026-07-30'},
  'factoresPositivos': ['Balance acumulado no negativo.'],
  'factoresNegativos': ['El margen de ahorro puede mejorar.'],
  'historial': [
    {'periodo': '2026-07', 'score': 78},
  ],
  'recomendaciones': ['Mantenga el seguimiento periódico.'],
};

http.Response _json(int status, Object body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);
