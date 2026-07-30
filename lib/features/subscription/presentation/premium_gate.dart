import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../domain/subscription_entity.dart';
import 'subscription_viewmodel.dart';
import '../../../core/services/pilot_local_store.dart';

class PremiumGate extends ConsumerWidget {
  final PremiumCapability capability;
  final Widget child;
  const PremiumGate({super.key, required this.capability, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionViewModelProvider);
    return subscription.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_) => child,
      empty: () => child,
      success: (value) {
        if (value.allows(capability) ||
            (capability == PremiumCapability.ocr &&
                PilotLocalStore.hasFreeOcrQuota)) {
          return child;
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppCard(
              elevation: AppCardElevation.elevated,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.workspace_premium_rounded, size: 52),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Funcionalidad Premium',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    capability == PremiumCapability.ocr
                        ? 'Usaste los 3 comprobantes OCR incluidos este mes. Activá Premium para continuar sin límite.'
                        : 'Activá un plan Premium para utilizar esta funcionalidad.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Ver planes',
                    onPressed: () => context.push(AppRoutes.subscription),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
