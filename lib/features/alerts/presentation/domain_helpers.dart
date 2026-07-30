import 'package:flutter/material.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/widgets/app_badge.dart';
import '../domain/alert_entity.dart';

AppBadgeTone alertLevelTone(AlertLevel level) {
  switch (level) {
    case AlertLevel.warning:
      return AppBadgeTone.warning;
    case AlertLevel.error:
      return AppBadgeTone.error;
    case AlertLevel.success:
      return AppBadgeTone.success;
    case AlertLevel.info:
      return AppBadgeTone.info;
  }
}

IconData alertLevelIcon(AlertLevel level) {
  switch (level) {
    case AlertLevel.warning:
      return Icons.warning_amber_rounded;
    case AlertLevel.error:
      return Icons.error_outline_rounded;
    case AlertLevel.success:
      return Icons.check_circle_outline_rounded;
    case AlertLevel.info:
      return Icons.info_outline_rounded;
  }
}

String alertLevelLabel(AlertLevel level) {
  switch (level) {
    case AlertLevel.warning:
      return 'Atención';
    case AlertLevel.error:
      return 'Importante';
    case AlertLevel.success:
      return 'Positivo';
    case AlertLevel.info:
      return 'Informativo';
  }
}

Color alertLevelColor(BuildContext context, AlertLevel level) {
  final colors = context.colors;
  switch (level) {
    case AlertLevel.warning:
      return colors.warning;
    case AlertLevel.error:
      return colors.error;
    case AlertLevel.success:
      return colors.success;
    case AlertLevel.info:
      return colors.info;
  }
}
