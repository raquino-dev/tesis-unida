import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_environment.dart';
import '../../../core/network/api_providers.dart';
import '../data/api_pilot_consent_repository.dart';

final pilotConsentRepositoryProvider = Provider<ApiPilotConsentRepository?>(
  (ref) => AppEnvironment.useApi
      ? ApiPilotConsentRepository(ref.watch(apiClientProvider))
      : null,
);
