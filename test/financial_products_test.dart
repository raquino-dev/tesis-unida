import 'package:finanzas_app/app/router/app_routes.dart';
import 'package:finanzas_app/app/theme/app_theme.dart';
import 'package:finanzas_app/core/services/pilot_local_store.dart';
import 'package:finanzas_app/features/accounts/presentation/account_list_screen.dart';
import 'package:finanzas_app/features/credit_cards/presentation/credit_card_detail_screen.dart';
import 'package:finanzas_app/features/movements/domain/movement_entity.dart';
import 'package:finanzas_app/features/movements/presentation/screens/add_edit_movement_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PilotLocalStore.resetMemoryForTesting();
    await PilotLocalStore.initialize();
  });

  testWidgets('muestra cuentas y tarjetas en la misma lista ordenable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AccountListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Efectivo'), findsWidgets);
    expect(find.text('Itaú Mastercard'), findsOneWidget);
    expect(find.textContaining('Tarjeta de crédito'), findsOneWidget);
    expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(5));
  });

  test('guarda el orden personalizado en memoria local', () async {
    const order = ['card:cc_itau', 'account:acc_efectivo'];

    await PilotLocalStore.saveFinancialProductsOrder(order);

    expect(PilotLocalStore.financialProductsOrder, order);
  });

  testWidgets('la tarjeta abre el alta con tipo y tarjeta preseleccionados', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    AddMovementArgs? receivedArgs;
    final router = GoRouter(
      initialLocation: AppRoutes.creditCardDetailPath('cc_itau'),
      routes: [
        GoRoute(
          path: '/credit-cards/:id',
          builder: (_, state) =>
              CreditCardDetailScreen(cardId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: AppRoutes.addMovement,
          builder: (_, state) {
            receivedArgs = state.extra as AddMovementArgs?;
            return const Scaffold(body: Text('Alta de movimiento'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Almuerzo'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Registrar egreso'));
    await tester.pumpAndSettle();

    expect(find.text('Alta de movimiento'), findsOneWidget);
    expect(receivedArgs?.initialCreditCardId, 'cc_itau');
    expect(receivedArgs?.initialAccountId, 'acc_credito_itau');
    expect(receivedArgs?.initialType, MovementType.expense);
  });
}
