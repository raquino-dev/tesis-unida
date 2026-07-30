import 'package:flutter/material.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../domain/movement_entity.dart';

class OcrStatusBadge extends StatelessWidget {
  final OcrStatus status;
  const OcrStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late String label;
    late AppBadgeTone tone;
    late IconData icon;
    switch (status) {
      case OcrStatus.pending:
        label = 'OCR pendiente';
        tone = AppBadgeTone.neutral;
        icon = Icons.hourglass_empty_rounded;
        break;
      case OcrStatus.processing:
        label = 'Procesando';
        tone = AppBadgeTone.info;
        icon = Icons.autorenew_rounded;
        break;
      case OcrStatus.success:
        label = 'OCR exitoso';
        tone = AppBadgeTone.success;
        icon = Icons.check_circle_outline_rounded;
        break;
      case OcrStatus.incomplete:
        label = 'Datos incompletos';
        tone = AppBadgeTone.warning;
        icon = Icons.error_outline_rounded;
        break;
      case OcrStatus.failed:
        label = 'OCR fallido';
        tone = AppBadgeTone.error;
        icon = Icons.close_rounded;
        break;
    }
    return AppBadge(label: label, tone: tone, icon: icon);
  }
}
