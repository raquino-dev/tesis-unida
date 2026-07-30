import 'package:flutter/material.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_theme_extension.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/movement_entity.dart';
import 'ocr_status_badge.dart';

class MovementCard extends StatelessWidget {
  final MovementEntity movement;
  final VoidCallback? onTap;

  const MovementCard({super.key, required this.movement, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isIncome = movement.type == MovementType.income;
    final amountColor = isIncome ? colors.success : colors.textPrimary;
    final sign = isIncome ? '+' : '-';
    final category = movement.primaryCategory;
    final extraCategories = movement.categories.length - 1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.16),
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Icon(category.icon, color: category.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.description,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            extraCategories > 0
                                ? '${category.name} +$extraCategories · ${movement.account.name}'
                                : '${category.name} · ${movement.account.name}',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (movement.ocrStatus != null) ...[
                      const SizedBox(height: 4),
                      OcrStatusBadge(status: movement.ocrStatus!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$sign${CurrencyFormatter.format(movement.amount)}',
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (movement.hasAttachment) ...[
                    const SizedBox(height: 4),
                    Icon(
                      Icons.attach_file_rounded,
                      size: 14,
                      color: colors.textMuted,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
