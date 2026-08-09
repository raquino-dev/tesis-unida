import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/network/api_providers.dart';
import '../data/api_pilot_instrument_repository.dart';

final pilotInstrumentRepositoryProvider =
    Provider<ApiPilotInstrumentRepository?>(
      (ref) => AppEnvironment.useApi
          ? ApiPilotInstrumentRepository(ref.watch(apiClientProvider))
          : null,
    );
