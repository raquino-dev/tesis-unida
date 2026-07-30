import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme_extension.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../../../core/widgets/app_state_view.dart';
import '../../domain/movement_entity.dart';
import '../viewmodels/movement_detail_viewmodel.dart';
import '../widgets/ocr_status_badge.dart';
import 'attachment_preview_screen.dart';

class MovementDetailScreen extends ConsumerWidget {
  final String movementId;
  const MovementDetailScreen({super.key, required this.movementId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(movementDetailViewModelProvider(movementId));
    final colors = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del movimiento')),
      body: state.when(
        loading: () => const AppLoadingState(),
        error: (message) => AppErrorState(message: message),
        empty: () => const AppEmptyState(
          title: 'Sin datos',
          message: 'No hay información para mostrar.',
        ),
        success: (movement) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                elevation: AppCardElevation.elevated,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: movement.primaryCategory.color.withValues(
                              alpha: 0.18,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            movement.primaryCategory.icon,
                            color: movement.primaryCategory.color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: movement.categories
                                .map(
                                  (c) => AppChip(
                                    label: c.name,
                                    accentColor: c.color,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      '${movement.type == MovementType.income ? '+' : '-'}${CurrencyFormatter.format(movement.amount)}',
                      style: TextStyle(
                        color: movement.type == MovementType.income
                            ? colors.success
                            : colors.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (movement.ocrStatus != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      OcrStatusBadge(status: movement.ocrStatus!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  children: [
                    _row(context, 'Fecha', DateFormatter.full(movement.date)),
                    const Divider(height: AppSpacing.lg),
                    Row(
                      children: [
                        Icon(
                          movement.account.icon,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cuenta',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        Text(
                          movement.account.name,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: AppSpacing.lg),
                    _row(context, 'Descripción', movement.description),
                  ],
                ),
              ),
              if (movement.hasAttachment) ...[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  elevation: AppCardElevation.elevated,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            movement.attachmentType == AttachmentType.pdf
                                ? Icons.picture_as_pdf_outlined
                                : movement.attachmentType == AttachmentType.xml
                                ? Icons.code_rounded
                                : Icons.image_outlined,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              movement.attachmentName ??
                                  (movement.attachmentType == AttachmentType.pdf
                                      ? 'Comprobante en PDF'
                                      : movement.attachmentType ==
                                            AttachmentType.xml
                                      ? 'Comprobante XML SIFEN'
                                      : 'Comprobante (imagen)'),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (movement.ocrStatus != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: AppRadius.mdRadius,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Información reconocida por OCR',
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _row(
                                context,
                                'Monto detectado',
                                CurrencyFormatter.format(movement.amount),
                              ),
                              const SizedBox(height: 4),
                              _row(
                                context,
                                'Comercio detectado',
                                movement.description,
                              ),
                              const SizedBox(height: 4),
                              _row(
                                context,
                                'Categoría sugerida',
                                movement.primaryCategory.name,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'El archivo original queda disponible junto con estos datos, incluso si luego los corregiste.',
                                style: TextStyle(
                                  color: colors.textMuted,
                                  fontSize: 11.5,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'Ver comprobante',
                        variant: AppButtonVariant.secondary,
                        icon: Icons.visibility_outlined,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                AttachmentPreviewScreen(movement: movement),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Editar movimiento',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.push(
                  '/movements/${movement.id}/edit',
                  extra: movement,
                ),
              ),
              if (movement.ocrStatus == OcrStatus.incomplete ||
                  movement.ocrStatus == OcrStatus.failed) ...[
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Reprocesar comprobante',
                  variant: AppButtonVariant.ghost,
                  onPressed: () => ref
                      .read(
                        movementDetailViewModelProvider(movementId).notifier,
                      )
                      .reprocessOcr(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final colors = context.colors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
