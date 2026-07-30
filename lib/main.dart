import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';
import 'core/services/pilot_local_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await PilotLocalStore.initialize();
  runApp(const ProviderScope(child: FinanzasApp()));
}
