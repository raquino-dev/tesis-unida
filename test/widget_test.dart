import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_app/app/app.dart';

void main() {
  testWidgets('App starts on onboarding screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FinanzasApp()));
    await tester.pump();

    expect(find.text('Omitir'), findsOneWidget);
  });
}
