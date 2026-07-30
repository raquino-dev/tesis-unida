import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/app_speed_dial_fab.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/movements/domain/movement_entity.dart';
import '../../features/movements/presentation/screens/movement_list_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import 'app_routes.dart';

const _addIndex = 2;

/// Contenedor de navegación principal con 5 tabs. El botón central de
/// "Añadir" no navega directamente: se expande y revela las acciones
/// principales (añadir gasto, añadir ingreso, escanear factura).
class AppShell extends StatefulWidget {
  final int initialIndex;
  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;
  bool _speedDialOpen = false;

  static const _screens = [
    DashboardScreen(),
    MovementListScreen(),
    SizedBox.shrink(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  void _onTap(int index) {
    if (index == _addIndex) {
      setState(() => _speedDialOpen = !_speedDialOpen);
      return;
    }
    setState(() => _index = index);
  }

  void _goToAddMovement(MovementType type) {
    context.push(AppRoutes.addMovement, extra: type);
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
            centerExpanded: _speedDialOpen,
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
                label: 'Reportes',
              ),
              AppBottomNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Perfil',
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: AppSpeedDialFab(
            isOpen: _speedDialOpen,
            onToggle: (open) => setState(() => _speedDialOpen = open),
            fabCenterFromBottom: AppBottomNav.fabCenterFromBottom(context),
            actions: [
              SpeedDialAction(
                icon: Icons.remove_circle_outline_rounded,
                label: 'Añadir gasto',
                onTap: () => _goToAddMovement(MovementType.expense),
              ),
              SpeedDialAction(
                icon: Icons.add_circle_outline_rounded,
                label: 'Añadir ingreso',
                onTap: () => _goToAddMovement(MovementType.income),
              ),
              SpeedDialAction(
                icon: Icons.document_scanner_outlined,
                label: 'Escanear factura',
                onTap: () => context.push(AppRoutes.ocr),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
