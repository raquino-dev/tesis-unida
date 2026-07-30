import 'package:flutter/material.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_shadows.dart';
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

/// Overlay del botón central expandible del bottom nav: al presionarse el
/// "+" (renderizado por [AppBottomNav]), esta capa revela un panel agrupado
/// con las acciones principales, flotando sobre un fondo que atenúa el
/// resto de la pantalla para que no se confunda con el contenido detrás.
class AppSpeedDialFab extends StatefulWidget {
  /// Alto total del panel (botón 52 + padding vertical 10 arriba y abajo),
  /// usado para que su centro quede alineado con [fabCenterFromBottom].
  static const double panelHeight = 72;

  final List<SpeedDialAction> actions;
  final bool isOpen;
  final ValueChanged<bool> onToggle;

  /// Distancia entre el borde inferior de la pantalla y el centro vertical
  /// del botón que despliega el panel. El panel se centra a esa misma altura.
  final double fabCenterFromBottom;

  const AppSpeedDialFab({
    super.key,
    required this.actions,
    required this.isOpen,
    required this.onToggle,
    required this.fabCenterFromBottom,
  });

  @override
  State<AppSpeedDialFab> createState() => _AppSpeedDialFabState();
}

class _AppSpeedDialFabState extends State<AppSpeedDialFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  @override
  void didUpdateWidget(covariant AppSpeedDialFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _controller.forward();
    } else if (!widget.isOpen && oldWidget.isOpen) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      ignoring: !widget.isOpen,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onToggle(false),
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.5 * _controller.value,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        widget.fabCenterFromBottom -
                        (AppSpeedDialFab.panelHeight / 2),
                  ),
                  child: FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(color: colors.border),
                          boxShadow: AppShadows.card(isDark),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            widget.actions.length * 2 - 1,
                            (i) {
                              if (i.isOdd) {
                                return Container(
                                  width: 1,
                                  height: 28,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  color: colors.border,
                                );
                              }
                              final action = widget.actions[i ~/ 2];
                              return _ActionButton(
                                action: action,
                                onTap: () {
                                  widget.onToggle(false);
                                  action.onTap();
                                },
                              );
                            },
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
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final SpeedDialAction action;
  final VoidCallback onTap;
  const _ActionButton({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: action.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.pillRadius,
          child: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            child: Icon(action.icon, color: colors.primary, size: 24),
          ),
        ),
      ),
    );
  }
}
