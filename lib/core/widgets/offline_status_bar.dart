import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../offline/offline_providers.dart';
import '../offline/offline_models.dart';
import '../offline/offline_runtime.dart';

class OfflineStatusBar extends ConsumerWidget {
  const OfflineStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(offlineStatusProvider).valueOrNull;
    if (status == null ||
        (status.online &&
            !status.syncing &&
            status.pending == 0 &&
            status.conflicts == 0 &&
            status.failed == 0)) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    final hasIssue = status.conflicts > 0 || status.failed > 0;
    final background = hasIssue
        ? colorScheme.errorContainer
        : status.online
        ? colorScheme.primaryContainer
        : colorScheme.secondaryContainer;
    final foreground = hasIssue
        ? colorScheme.onErrorContainer
        : status.online
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSecondaryContainer;
    final label = status.conflicts > 0
        ? '${status.conflicts} cambio${status.conflicts == 1 ? '' : 's'} requiere${status.conflicts == 1 ? '' : 'n'} revisión'
        : status.failed > 0
        ? '${status.failed} cambio${status.failed == 1 ? '' : 's'} no pudo${status.failed == 1 ? '' : 'ieron'} sincronizarse'
        : status.syncing
        ? 'Sincronizando ${status.pending} cambio${status.pending == 1 ? '' : 's'}…'
        : status.online
        ? '${status.pending} cambio${status.pending == 1 ? '' : 's'} pendiente${status.pending == 1 ? '' : 's'}'
        : 'Sin conexión · ${status.pending} cambio${status.pending == 1 ? '' : 's'} pendiente${status.pending == 1 ? '' : 's'}';
    return Material(
      color: background,
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: hasIssue
              ? () => _showIssues(context)
              : status.online
              ? () => OfflineRuntime.instance.synchronize()
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasIssue
                      ? Icons.sync_problem_rounded
                      : status.syncing
                      ? Icons.sync_rounded
                      : status.online
                      ? Icons.cloud_upload_outlined
                      : Icons.cloud_off_rounded,
                  size: 17,
                  color: foreground,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showIssues(BuildContext context) async {
    final issues = await OfflineRuntime.instance.synchronizationIssues();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cambios que requieren atención',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Los conflictos no se sobrescriben automáticamente. Podés descartar el cambio local y conservar la versión del servidor.',
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: issues.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, index) {
                    final operation = issues[index];
                    final conflict =
                        operation.status == OfflineOperationStatus.conflict;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        conflict
                            ? Icons.sync_problem_rounded
                            : Icons.error_outline_rounded,
                      ),
                      title: Text(_entityLabel(operation.entityType)),
                      subtitle: Text(
                        operation.lastError ?? 'No se pudo sincronizar.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: conflict
                          ? TextButton(
                              onPressed: () async {
                                await OfflineRuntime.instance.discardOperation(
                                  operation,
                                );
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              },
                              child: const Text('Descartar'),
                            )
                          : null,
                    );
                  },
                ),
              ),
              if (issues.any(
                (item) => item.status == OfflineOperationStatus.failed,
              )) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    await OfflineRuntime.instance.retryFailedOperations();
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar fallidos'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _entityLabel(String value) => switch (value) {
    'cuenta' => 'Cuenta',
    'categoria' => 'Categoría',
    'movimiento' => 'Movimiento',
    'presupuesto' => 'Presupuesto',
    'meta_ahorro' => 'Meta de ahorro',
    'movimiento_recurrente' => 'Movimiento recurrente',
    'tarjeta_credito' => 'Tarjeta por alias',
    'consentimiento' => 'Consentimiento',
    'respuesta_instrumento' => 'Encuesta del piloto',
    _ => 'Cambio pendiente',
  };
}

class OnlineRequired extends ConsumerWidget {
  const OnlineRequired({
    super.key,
    required this.featureName,
    required this.child,
  });

  final String featureName;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(offlineStatusProvider).valueOrNull;
    if (status?.online ?? true) return child;
    return Scaffold(
      appBar: AppBar(title: Text(featureName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                'Esta función necesita conexión',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '$featureName requiere una conexión segura. Tus demás datos siguen disponibles sin internet.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: () => OfflineRuntime.instance.synchronize(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Comprobar conexión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
