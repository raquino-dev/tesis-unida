import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../network/api_client.dart';
import '../services/pilot_local_store.dart';
import 'offline_runtime.dart';

const _uniqueTask = 'finanzas-offline-periodic-sync';
const _taskName = 'offline_data_sync';

@pragma('vm:entry-point')
void offlineSyncCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != _taskName && task != Workmanager.iOSBackgroundTask) {
      return true;
    }
    WidgetsFlutterBinding.ensureInitialized();
    ApiClient? api;
    try {
      await PilotLocalStore.initialize();
      await OfflineRuntime.instance.initialize();
      api = ApiClient();
      await OfflineRuntime.instance.synchronize();
      // Un conflicto de negocio requiere intervención del usuario y no debe
      // provocar que el sistema operativo repita indefinidamente la tarea.
      return true;
    } catch (_) {
      return false;
    } finally {
      api?.close();
    }
  });
}

Future<void> configureOfflineBackgroundSync() async {
  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS)) {
    return;
  }
  try {
    await Workmanager().initialize(offlineSyncCallbackDispatcher);
    await Workmanager().registerPeriodicTask(
      _uniqueTask,
      _taskName,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  } catch (error, stackTrace) {
    // El planificador es una optimización: la sincronización al reabrir la app
    // sigue disponible aunque el sistema operativo rechace el registro.
    debugPrint('No se pudo registrar la sincronización periódica: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}
