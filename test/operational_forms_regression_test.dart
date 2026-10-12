import 'package:finanzas_app/app/theme/app_theme.dart';
import 'package:finanzas_app/core/widgets/app_button.dart';
import 'package:finanzas_app/core/widgets/app_searchable_selector.dart';
import 'package:finanzas_app/features/categories/presentation/category_list_screen.dart';
import 'package:finanzas_app/features/recurring_movements/domain/recurring_movement_entity.dart';
import 'package:finanzas_app/features/recurring_movements/presentation/recurring_movement_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  testWidgets(
    'la recurrencia usa selectores y no pide cantidad de repeticiones',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light,
            home: const RecurringMovementListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Cantidad de repeticiones'), findsNothing);
      expect(find.text('Crear categoría'), findsNothing);
      expect(find.text('Crear cuenta'), findsNothing);
      expect(find.text('Crear tarjeta'), findsNothing);

      final frequencySelector = find.byWidgetPredicate(
        (widget) => widget is AppSearchableSingleSelector<RecurrenceFrequency>,
      );
      expect(frequencySelector, findsOneWidget);
      expect(
        tester
            .widget<AppSearchableSingleSelector<RecurrenceFrequency>>(
              frequencySelector,
            )
            .value,
        RecurrenceFrequency.monthly,
      );
    },
  );

  testWidgets('muestra loader mientras crea una categoría', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CategoryListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Categoría de prueba');
    await tester.pump();

    final createButton = find.widgetWithText(AppButton, 'Crear categoría');
    await tester.tap(createButton);
    await tester.pump();

    expect(
      tester.widget<AppButton>(find.byType(AppButton).last).isLoading,
      isTrue,
    );
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    await tester.pumpAndSettle();
    expect(find.text('Categoría de prueba'), findsOneWidget);
  });
}
