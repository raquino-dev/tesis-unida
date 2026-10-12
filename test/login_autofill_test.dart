import 'package:finanzas_app/app/theme/app_theme.dart';
import 'package:finanzas_app/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('expone usuario y contraseña al autocompletado del dispositivo', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: const LoginScreen()),
      ),
    );

    expect(find.byType(AutofillGroup), findsOneWidget);

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields, hasLength(2));
    expect(
      fields.first.autofillHints,
      containsAll(<String>[AutofillHints.username, AutofillHints.email]),
    );
    expect(fields.first.textInputAction, TextInputAction.next);
    expect(fields.last.autofillHints, const <String>[AutofillHints.password]);
    expect(fields.last.textInputAction, TextInputAction.done);
  });
}
