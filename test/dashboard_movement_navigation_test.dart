import 'package:finanzas_app/app/router/app_shell.dart';
import 'package:finanzas_app/app/theme/app_theme.dart';
import 'package:finanzas_app/features/movements/domain/movement_entity.dart';
import 'package:finanzas_app/features/movements/presentation/viewmodels/movement_list_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets(
    'permite abrir ingresos y luego gastos después de volver a Inicio',
    (tester) async {
      await initializeDateFormatting('es');
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(theme: AppTheme.light, home: const AppShell()),
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AppShell)),
      );

      await tester.tap(find.text('Ingresos del mes'));
      await tester.pump();
      expect(
        container.read(movementListViewModelProvider.notifier).filters.type,
        MovementType.income,
      );

      await tester.tap(find.text('Inicio'));
      await tester.pump();
      expect(find.text('Gastos del mes'), findsOneWidget);

      await tester.tap(find.text('Gastos del mes'));
      await tester.pump();
      expect(
        container.read(movementListViewModelProvider.notifier).filters.type,
        MovementType.expense,
      );
      expect(find.text('Movimientos'), findsWidgets);
    },
  );
}
