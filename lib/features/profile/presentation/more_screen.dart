import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/widgets/app_card.dart';

/// Punto de entrada para las áreas secundarias de Finanza.
///
/// Mantiene el perfil como una pantalla propia, tal como la nueva navegación,
/// y hace visibles funcionalidades que antes quedaban escondidas en ajustes.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Más'),
        actions: [
          IconButton(
            tooltip: 'Configuración',
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          _MenuCard(
            color: const Color(0xFF00A86B),
            icon: Icons.person_outline_rounded,
            title: 'Mi perfil',
            subtitle: 'Ver y editar mi información',
            onTap: () => context.push(AppRoutes.profile),
          ),
          const SizedBox(height: 8),
          _MenuCard(
            color: const Color(0xFF3187E8),
            icon: Icons.account_balance_wallet_outlined,
            title: 'Cuentas y tarjetas',
            subtitle: 'Administrá tus cuentas',
            onTap: () => context.push(AppRoutes.accounts),
          ),
          const SizedBox(height: 8),
          _MenuCard(
            color: const Color(0xFF00A86B),
            icon: Icons.swap_horiz_rounded,
            title: 'Transferencias',
            subtitle: 'Mové dinero entre tus cuentas',
            onTap: () => context.push(AppRoutes.transfers),
          ),
          const SizedBox(height: 8),
          _MenuCard(
            color: const Color(0xFF3187E8),
            icon: Icons.autorenew_rounded,
            title: 'Recurrentes',
            subtitle: 'Gestioná tus pagos',
            onTap: () => context.push(AppRoutes.recurringMovements),
          ),
          const SizedBox(height: 8),
          _MenuCard(
            color: const Color(0xFFB94BE8),
            icon: Icons.groups_2_outlined,
            title: 'Familia',
            subtitle: 'Compartí y organizá',
            onTap: () => context.push(AppRoutes.family),
          ),
          const SizedBox(height: 8),
          _MenuCard(
            color: const Color(0xFF00A86B),
            icon: Icons.shield_outlined,
            title: 'Seguridad',
            subtitle: 'Protegé tu cuenta',
            onTap: () => context.push(AppRoutes.security),
          ),
          const SizedBox(height: 8),
          _MenuCard(
            color: const Color(0xFFFF5D75),
            icon: Icons.science_outlined,
            title: 'Piloto',
            subtitle: 'Ayudanos a mejorar',
            onTap: () => context.push(AppRoutes.pilot),
          ),
          const SizedBox(height: 8),
          _MenuCard(
            color: colors.textMuted,
            icon: Icons.tune_rounded,
            title: 'Configuración',
            subtitle: 'Preferencias de la app',
            onTap: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: colors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.textMuted),
        ],
      ),
    );
  }
}
