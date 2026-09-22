import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_speed_dial_fab.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/movements/domain/movement_entity.dart';
import '../../features/movements/presentation/screens/movement_list_screen.dart';
import '../../features/movements/presentation/screens/add_edit_movement_screen.dart';
import '../../features/movements/presentation/viewmodels/movement_list_viewmodel.dart';
import '../../features/profile/presentation/more_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import 'app_routes.dart';

const _addIndex = 2;

/// Contenedor de navegación principal con 5 tabs. El botón central de
/// "Añadir" no navega directamente: se expande y revela las acciones
/// principales (añadir gasto, añadir ingreso, escanear factura).
class AppShell extends ConsumerStatefulWidget {
  final int initialIndex;
  const AppShell({super.key, this.initialIndex = 0});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late int _index = widget.initialIndex;
  bool _speedDialOpen = false;
  bool _speedDialCenterVisible = false;

  static const _screens = [
    DashboardScreen(),
    MovementListScreen(),
    SizedBox.shrink(),
    ReportsScreen(),
    MoreScreen(),
  ];

  void _onTap(int index) {
    if (index == _addIndex) {
      _setSpeedDialOpen(!_speedDialOpen);
      return;
    }
    setState(() => _index = index);
  }

  void _setSpeedDialOpen(bool open) {
    setState(() {
      _speedDialOpen = open;
      if (open) _speedDialCenterVisible = true;
    });
  }

  void _onSpeedDialClosed() {
    if (!mounted || _speedDialOpen || !_speedDialCenterVisible) return;
    setState(() => _speedDialCenterVisible = false);
  }

  void _goToAddMovement(MovementType type) {
    final accountId = _index == 1
        ? ref.read(movementListViewModelProvider.notifier).filters.accountId
        : null;
    context.push(
      AppRoutes.addMovement,
      extra: AddMovementArgs(initialType: type, initialAccountId: accountId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(index: _index, children: _screens),
          bottomNavigationBar: AppBottomNav(
            currentIndex: _index,
            onTap: _onTap,
            addIndex: _addIndex,
            centerExpanded: _speedDialCenterVisible,
            items: const [
              AppBottomNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Inicio',
              ),
              AppBottomNavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Movimientos',
              ),
              AppBottomNavItem(
                icon: Icons.add_rounded,
                activeIcon: Icons.add_rounded,
                label: 'Añadir',
              ),
              AppBottomNavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Análisis',
              ),
              AppBottomNavItem(
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view_rounded,
                label: 'Más',
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: AppSpeedDialFab(
            isOpen: _speedDialOpen,
            centerVisible: _speedDialCenterVisible,
            onToggle: _setSpeedDialOpen,
            onClosed: _onSpeedDialClosed,
            fabCenterFromBottom: AppBottomNav.fabCenterFromBottom(context),
            actions: [
              SpeedDialAction(
                icon: Icons.arrow_circle_up_outlined,
                label: 'Ingreso',
                onTap: () => _goToAddMovement(MovementType.income),
              ),
              SpeedDialAction(
                icon: Icons.arrow_circle_down_outlined,
                label: 'Gasto',
                onTap: () => _goToAddMovement(MovementType.expense),
              ),
              SpeedDialAction(
                icon: Icons.document_scanner_outlined,
                label: 'OCR',
                onTap: () => context.push(AppRoutes.ocr),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
