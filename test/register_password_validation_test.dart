import 'package:finanzas_app/app/theme/app_theme.dart';
import 'package:finanzas_app/features/auth/presentation/screens/register_screen.dart';
import 'package:finanzas_app/core/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('valida la contraseña y su confirmación mientras se escriben', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.dark, home: const RegisterScreen()),
      ),
    );

    final passwordField = find.descendant(
      of: find.widgetWithText(AppTextField, 'Contraseña'),
      matching: find.byType(TextField),
    );
    final confirmationField = find.descendant(
      of: find.widgetWithText(AppTextField, 'Confirmar contraseña'),
      matching: find.byType(TextField),
    );
    await tester.enterText(passwordField, 'Corta#1');
    await tester.pump();

    expect(
      find.text('La contraseña debe tener entre 12 y 128 caracteres.'),
      findsOneWidget,
    );

    await tester.enterText(passwordField, 'Piloto#Seguro2026');
    await tester.pump();

    expect(
      find.text('La contraseña debe tener entre 12 y 128 caracteres.'),
      findsNothing,
    );

    await tester.enterText(confirmationField, 'Piloto#Distinto2026');
    await tester.pump();
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);

    await tester.enterText(confirmationField, 'Piloto#Seguro2026');
    await tester.pump();
    expect(find.text('Las contraseñas no coinciden.'), findsNothing);
  });
}
