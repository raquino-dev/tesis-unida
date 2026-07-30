import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme_extension.dart';
import '../../domain/movement_entity.dart';

/// Visor local del archivo elegido durante el piloto. Las imágenes se muestran
/// dentro de la app; PDF y XML pueden abrirse/compartirse con una aplicación
/// instalada en el dispositivo.
class AttachmentPreviewScreen extends StatelessWidget {
  final MovementEntity movement;
  const AttachmentPreviewScreen({super.key, required this.movement});

  @override
  Widget build(BuildContext context) {
    final isImage = movement.attachmentType == AttachmentType.image;
    return Scaffold(
      appBar: AppBar(title: Text(isImage ? 'Comprobante' : 'Comprobante PDF')),
      body: isImage
          ? _ImagePreview(movement: movement)
          : _PdfPreview(movement: movement),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final MovementEntity movement;
  const _ImagePreview({required this.movement});

  @override
  Widget build(BuildContext context) {
    final path = movement.attachmentPath;
    if (path != null && File(path).existsSync()) {
      return Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Center(child: Image.file(File(path), fit: BoxFit.contain)),
            ),
          ),
          _ShareFileButton(movement: movement),
        ],
      );
    }
    final category = movement.primaryCategory;
    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Center(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  margin: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.martinique, AppColors.mirage],
                    ),
                    borderRadius: AppRadius.lgRadius,
                    border: Border.all(
                      color: AppColors.comet.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 72,
                        color: category.color,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        movement.description,
                        style: const TextStyle(
                          color: AppColors.textPrimaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'El archivo local ya no está disponible.',
                        style: const TextStyle(
                          color: AppColors.textMutedDark,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Pellizcá para acercar o alejar la imagen del comprobante.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.colors.textMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _PdfPreview extends StatelessWidget {
  final MovementEntity movement;
  const _PdfPreview({required this.movement});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final path = movement.attachmentPath;
    final available = path != null && File(path).existsSync();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: AppRadius.lgRadius,
                border: Border.all(color: colors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 72,
                    color: colors.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    movement.attachmentName ??
                        '${movement.description}.${movement.attachmentType == AttachmentType.xml ? 'xml' : 'pdf'}',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    available
                        ? 'Archivo disponible en el dispositivo'
                        : 'El archivo local ya no está disponible',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (available) _ShareFileButton(movement: movement),
        ],
      ),
    );
  }
}

class _ShareFileButton extends StatelessWidget {
  final MovementEntity movement;
  const _ShareFileButton({required this.movement});

  @override
  Widget build(BuildContext context) {
    final path = movement.attachmentPath;
    if (path == null || !File(path).existsSync()) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: FilledButton.icon(
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text('Abrir o compartir archivo'),
        onPressed: () => SharePlus.instance.share(
          ShareParams(
            files: [XFile(path)],
            subject: movement.attachmentName ?? 'Comprobante',
          ),
        ),
      ),
    );
  }
}
