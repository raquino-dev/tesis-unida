import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'offline_models.dart';
import 'offline_runtime.dart';

final offlineStatusProvider = StreamProvider<OfflineSyncSnapshot>((ref) async* {
  yield OfflineRuntime.instance.snapshot;
  yield* OfflineRuntime.instance.changes;
});
