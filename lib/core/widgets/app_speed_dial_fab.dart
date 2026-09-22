import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_theme_extension.dart';

class SpeedDialAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SpeedDialAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// Menú radial que nace del botón central de la barra de navegación.
class AppSpeedDialFab extends StatefulWidget {
  final List<SpeedDialAction> actions;
  final bool isOpen;
  final bool centerVisible;
  final ValueChanged<bool> onToggle;
  final VoidCallback onClosed;
  final double fabCenterFromBottom;

  const AppSpeedDialFab({
    super.key,
    required this.actions,
    required this.isOpen,
    required this.centerVisible,
    required this.onToggle,
    required this.onClosed,
    required this.fabCenterFromBottom,
  });

  @override
  State<AppSpeedDialFab> createState() => _AppSpeedDialFabState();
}

class _AppSpeedDialFabState extends State<AppSpeedDialFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 270),
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) widget.onClosed();
    });
  }

  @override
  void didUpdateWidget(covariant AppSpeedDialFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      widget.isOpen ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.isOpen,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final origin = Offset(width / 2, height - widget.fabCenterFromBottom);
          final center = origin.translate(0, -36);
          final sideX = math.min(width * .26, 108.0);
          final sideRise = math.min(height * .135, 110.0);
          final topRise = math.min(height * .22, 180.0);
          final positions = [
            center.translate(-sideX, -sideRise),
            center.translate(0, -topRise),
            center.translate(sideX, -sideRise),
          ];

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = _controller.value;
              return Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onToggle(false),
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: .46 * value),
                      ),
                    ),
                  ),
                  for (
                    var index = 0;
                    index < widget.actions.length && index < positions.length;
                    index++
                  )
                    _buildAction(
                      action: widget.actions[index],
                      position: positions[index],
                      origin: origin,
                      index: index,
                      value: value,
                    ),
                  Positioned(
                    left: center.dx - 26,
                    top: center.dy - 26,
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        36 * (1 - Curves.easeOut.transform(value)),
                      ),
                      child: Opacity(
                        opacity: widget.centerVisible ? 1 : 0,
                        child: Material(
                          color: AppColors.emerald,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => widget.onToggle(false),
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: 52,
                              height: 52,
                              child: Transform.rotate(
                                angle: math.pi / 4 * value,
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAction({
    required SpeedDialAction action,
    required Offset position,
    required Offset origin,
    required int index,
    required double value,
  }) {
    final colors = context.colors;
    final start = index == 1 ? .08 : .15;
    final progress = ((value - start) / (1 - start)).clamp(0.0, 1.0);
    final curved = Curves.easeOutCubic.transform(progress);
    const actionWidth = 92.0;
    const iconSize = 60.0;

    void select() {
      widget.onToggle(false);
      action.onTap();
    }

    return Positioned(
      left: position.dx - actionWidth / 2,
      top: position.dy - iconSize / 2,
      child: Transform.translate(
        offset: Offset(
          (origin.dx - position.dx) * (1 - curved),
          (origin.dy - position.dy) * (1 - curved),
        ),
        child: Transform.scale(
          scale: .45 + .55 * curved,
          child: Opacity(
            opacity: progress,
            child: Column(
              children: [
                Material(
                  color: Colors.white,
                  shape: CircleBorder(
                    side: BorderSide(color: colors.primary, width: 1.1),
                  ),
                  child: InkWell(
                    onTap: select,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: iconSize,
                      height: iconSize,
                      child: Icon(action.icon, color: colors.primary, size: 27),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -2),
                  child: Material(
                    color: const Color(0xFFF1FFFB),
                    borderRadius: AppRadius.pillRadius,
                    child: InkWell(
                      onTap: select,
                      borderRadius: AppRadius.pillRadius,
                      child: SizedBox(
                        width: actionWidth,
                        height: 28,
                        child: Center(
                          child: Text(
                            action.label,
                            style: const TextStyle(
                              color: AppColors.forest,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
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
}
