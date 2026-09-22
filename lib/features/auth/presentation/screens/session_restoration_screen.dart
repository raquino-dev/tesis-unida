import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/finanza_mark.dart';
import '../providers/auth_providers.dart';

class SessionRestorationScreen extends ConsumerWidget {
  const SessionRestorationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(sessionRestorationStatusProvider);
    final unavailable = status == SessionRestorationStatus.unavailable;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const FinanzaMark(size: 68),
                const SizedBox(height: 24),
                if (unavailable)
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 36,
                    color: AppColors.textMutedLight,
                  )
                else
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.emerald,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  unavailable
                      ? 'No pudimos verificar tu sesión'
                      : 'Recuperando tu sesión…',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.forest,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (unavailable) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Revisá tu conexión y volvé a intentar. Tu sesión continúa guardada.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMutedLight),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () =>
                        ref.read(currentUserProvider.notifier).restoreSession(),
                    child: const Text('Reintentar'),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(currentUserProvider.notifier)
                        .discardRememberedSession(),
                    child: const Text('Iniciar sesión con otra cuenta'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
