import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app/app.dart';
import 'core/config/app_environment.dart';
import 'core/services/pilot_local_store.dart';
import 'features/notifications/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await PilotLocalStore.initialize();
  if (AppEnvironment.firebaseConfigured) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  runApp(const ProviderScope(child: FinanzasApp()));
}
