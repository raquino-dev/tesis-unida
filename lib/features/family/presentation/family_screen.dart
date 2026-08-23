import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_section_header.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_searchable_selector.dart';
import '../../accounts/domain/account_entity.dart';
import '../../accounts/presentation/account_providers.dart';
import '../../categories/domain/category_entity.dart';
import '../../auth/domain/user_alias_policy.dart';
import '../../security/presentation/widgets/otp_verification_dialog.dart';
import '../domain/family_entity.dart';
import '../domain/family_repository.dart';
import 'family_providers.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(familyViewModelProvider);
    final viewModel = ref.read(familyViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión familiar'),
        actions: [
          IconButton(
            tooltip: 'Aceptar invitación',
            icon: const Icon(Icons.mark_email_read_outlined),
            onPressed: () => context.push(AppRoutes.invitationAcceptance),
          ),
        ],
      ),
      body: state.when(
        loading: () => const AppLoadingState(),
        error: (message) =>
            AppErrorState(message: message, onRetry: viewModel.load),
        empty: () => _CreateGroupState(onCreate: viewModel.createGroup),
        success: (group) => _FamilyOverview(group: group),
      ),
    );
  }
}

class _CreateGroupState extends StatefulWidget {
  final Future<String?> Function(String) onCreate;
  const _CreateGroupState({required this.onCreate});

  @override
  State<_CreateGroupState> createState() => _CreateGroupStateState();
}

class _CreateGroupStateState extends State<_CreateGroupState> {
  final _name = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.groups_2_outlined,
                size: 36,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Creá tu grupo familiar',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Compartí cuentas y gastos con tu familia, manteniendo tus movimientos personales separados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Nombre del grupo',
              controller: _name,
              hint: 'Ej. Familia Aquino',
              onChanged: (_) => setState(() => _error = null),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: TextStyle(color: colors.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Crear grupo',
              isLoading: _loading,
              onPressed: _name.text.trim().isEmpty
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      final error = await widget.onCreate(_name.text.trim());
                      if (!mounted) return;
                      setState(() {
                        _loading = false;
                        _error = error;
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyOverview extends ConsumerWidget {
  final FamilyGroupEntity group;
  const _FamilyOverview({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final currentMemberId = group.currentMemberId ?? 'you';
    final me = group.members.firstWhere(
      (m) => m.id == currentMemberId,
      orElse: () => group.members.first,
    );
    final canManage = group.currentRole.canManageGroup;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        AppCard(
          elevation: AppCardElevation.elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(group.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                '${group.members.length} integrantes · ${group.sharedAccounts.length} cuentas compartidas',
                style: TextStyle(color: colors.textSecondary, fontSize: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Caja y presupuestos',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.push(AppRoutes.familyTreasury),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                label: 'Reporte familiar',
                variant: AppButtonVariant.secondary,
                onPressed: () => context.push(AppRoutes.familyReports),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSectionHeader(
          title: 'Integrantes',
          actionLabel: canManage ? 'Invitar' : null,
          onAction: canManage ? () => _openInviteSheet(context) : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        ...group.members.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: colors.primary.withValues(alpha: 0.2),
                    child: Text(
                      m.name.substring(0, 1),
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${m.name}${m.id == currentMemberId ? ' (vos)' : ''}',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          m.email,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppBadge(
                    label: m.role.label,
                    tone: m.role == FamilyRole.owner
                        ? AppBadgeTone.premium
                        : AppBadgeTone.info,
                  ),
                  if (canManage && m.role != FamilyRole.owner) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        final viewModel = ref.read(
                          familyViewModelProvider.notifier,
                        );
                        if (value == 'promote') {
                          await viewModel.updateMemberRole(
                            m.id,
                            FamilyRole.admin,
                          );
                        } else if (value == 'demote') {
                          await viewModel.updateMemberRole(
                            m.id,
                            FamilyRole.member,
                          );
                        } else if (value == 'remove') {
                          final error = await viewModel.removeMember(m.id);
                          if (error != null && context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        if (m.role != FamilyRole.admin)
                          const PopupMenuItem(
                            value: 'promote',
                            child: Text('Hacer administrador'),
                          ),
                        if (m.role != FamilyRole.member)
                          const PopupMenuItem(
                            value: 'demote',
                            child: Text('Hacer integrante'),
                          ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('Quitar del grupo'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (canManage) ...[
          const SizedBox(height: AppSpacing.sm),
          ref
              .watch(familyInvitationsProvider)
              .when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
                data: (invitations) => invitations.isEmpty
                    ? const SizedBox.shrink()
                    : AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Invitaciones pendientes',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            ...invitations
                                .where(
                                  (item) =>
                                      item.status ==
                                      FamilyInvitationStatus.pending,
                                )
                                .map(
                                  (invitation) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      invitation.email.isNotEmpty
                                          ? invitation.email
                                          : invitation.userIdentifier,
                                    ),
                                    subtitle: Text(
                                      invitation.code.isEmpty
                                          ? 'Rol: ${invitation.role.label}'
                                          : 'Código: ${invitation.code}',
                                    ),
                                    trailing: IconButton(
                                      tooltip: 'Revocar invitación',
                                      icon: const Icon(Icons.close_rounded),
                                      onPressed: () async {
                                        await ref
                                            .read(familyRepositoryProvider)
                                            .revokeInvitation(invitation.id);
                                        ref.invalidate(
                                          familyInvitationsProvider,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
              ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppSectionHeader(
          title: 'Cuentas compartidas',
          actionLabel: canManage ? 'Administrar' : null,
          onAction: canManage ? () => _openSharedAccountsSheet(context) : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (group.sharedAccounts.isEmpty)
          Text(
            'Todavía no compartiste ninguna cuenta con el grupo.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          )
        else
          AppCard(
            child: Column(
              children: group.sharedAccounts.map((a) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(a.icon, size: 18, color: colors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          a.name,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatCompact(a.initialBalance),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Movimientos de la caja compartida',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => _openFamilyFilterSheet(context, group),
            ),
            if (group.sharedAccounts.isNotEmpty)
              TextButton(
                onPressed: () => _openAddMovementSheet(context, group, me),
                child: const Text('Añadir'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        const _FamilyMovementList(),
        if (me.role == FamilyRole.owner) ...[
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Eliminar grupo familiar',
            variant: AppButtonVariant.ghost,
            onPressed: () async {
              final verificationId = await requestOtpVerification(
                context,
                ref,
                reason: 'Eliminar grupo familiar',
              );
              if (verificationId == null) return;
              await ref
                  .read(familyRepositoryProvider)
                  .deleteFamilyGroup(verificationId);
              await ref.read(familyViewModelProvider.notifier).load();
            },
          ),
        ],
      ],
    );
  }

  void _openInviteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _InviteMemberSheet(),
    );
  }

  void _openSharedAccountsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SharedAccountsSheet(group: group),
    );
  }

  void _openAddMovementSheet(
    BuildContext context,
    FamilyGroupEntity group,
    FamilyMemberEntity me,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFamilyMovementSheet(group: group, currentMember: me),
    );
  }

  void _openFamilyFilterSheet(BuildContext context, FamilyGroupEntity group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FamilyFilterSheet(group: group),
    );
  }
}

class _FamilyFilterSheet extends ConsumerStatefulWidget {
  final FamilyGroupEntity group;
  const _FamilyFilterSheet({required this.group});

  @override
  ConsumerState<_FamilyFilterSheet> createState() => _FamilyFilterSheetState();
}

class _FamilyFilterSheetState extends ConsumerState<_FamilyFilterSheet> {
  late FamilyMovementFilters _draft = ref
      .read(familyMovementListViewModelProvider.notifier)
      .filters;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categoriesState = ref.watch(familyCategoriesProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () =>
                      setState(() => _draft = const FamilyMovementFilters()),
                  child: const Text('Restablecer'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Integrante',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.group.members.map((m) {
                final selected = _draft.memberId == m.id;
                return GestureDetector(
                  onTap: () => setState(
                    () => _draft = selected
                        ? _draft.copyWith(clearMember: true)
                        : _draft.copyWith(memberId: m.id),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? colors.primary : colors.surfaceElevated,
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Text(
                      m.name,
                      style: TextStyle(
                        color: selected ? Colors.white : colors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Tipo',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _typeOption(context, 'Todos', null),
                _typeOption(context, 'Gastos', FamilyMovementType.expense),
                _typeOption(context, 'Ingresos', FamilyMovementType.income),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Categoría',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            categoriesState.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
              data: (categories) => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((c) {
                  final selected = _draft.categoryId == c.id;
                  return GestureDetector(
                    onTap: () => setState(
                      () => _draft = selected
                          ? _draft.copyWith(clearCategory: true)
                          : _draft.copyWith(categoryId: c.id),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? c.color : colors.surfaceElevated,
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Text(
                        c.name,
                        style: TextStyle(
                          color: selected ? Colors.white : colors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Cuenta',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.group.sharedAccounts.map((a) {
                final selected = _draft.accountId == a.id;
                return GestureDetector(
                  onTap: () => setState(
                    () => _draft = selected
                        ? _draft.copyWith(clearAccount: true)
                        : _draft.copyWith(accountId: a.id),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? colors.primary : colors.surfaceElevated,
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Text(
                      a.name,
                      style: TextStyle(
                        color: selected ? Colors.white : colors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Aplicar filtros',
              onPressed: () {
                ref
                    .read(familyMovementListViewModelProvider.notifier)
                    .updateFilters(_draft);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeOption(
    BuildContext context,
    String label,
    FamilyMovementType? value,
  ) {
    final colors = context.colors;
    final selected = _draft.type == value;
    return GestureDetector(
      onTap: () => setState(
        () => _draft = value == null
            ? _draft.copyWith(clearType: true)
            : _draft.copyWith(type: value),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceElevated,
          borderRadius: AppRadius.pillRadius,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : colors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InviteMemberSheet extends ConsumerStatefulWidget {
  const _InviteMemberSheet();

  @override
  ConsumerState<_InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends ConsumerState<_InviteMemberSheet> {
  final _alias = TextEditingController();
  FamilyRole _role = FamilyRole.member;
  String? _error;

  @override
  void dispose() {
    _alias.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invitar integrante',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Alias único',
              hint: '@Rodrigo001',
              controller: _alias,
              prefixIcon: const Icon(Icons.alternate_email_rounded),
              errorText: _alias.text.isEmpty
                  ? null
                  : UserAliasPolicy.validate(_alias.text),
              onChanged: (_) => setState(() => _error = null),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'La invitación se asociará directamente a la cuenta que tenga este alias.',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Rol',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [FamilyRole.admin, FamilyRole.member].map((r) {
                final selected = r == _role;
                return GestureDetector(
                  onTap: () => setState(() => _role = r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? colors.primary : colors.surfaceElevated,
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Text(
                      r.label,
                      style: TextStyle(
                        color: selected ? Colors.white : colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: TextStyle(color: colors.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Invitar',
              onPressed: UserAliasPolicy.validate(_alias.text) != null
                  ? null
                  : () async {
                      try {
                        final invitation = await ref
                            .read(familyRepositoryProvider)
                            .createInvitation(
                              email: '',
                              userIdentifier: UserAliasPolicy.normalize(
                                _alias.text,
                              ),
                              invitedName: _alias.text.trim(),
                              role: _role,
                            );
                        ref.invalidate(familyInvitationsProvider);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                invitation.token == null
                                    ? 'Invitación creada. Código: ${invitation.code}'
                                    : 'Invitación creada. Código: ${invitation.code} · Token: ${invitation.token}',
                              ),
                            ),
                          );
                        }
                      } catch (error) {
                        setState(
                          () => _error = appErrorMessage(
                            error,
                            fallback: 'No pudimos crear la invitación.',
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedAccountsSheet extends ConsumerWidget {
  final FamilyGroupEntity group;
  const _SharedAccountsSheet({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final accountsState = ref.watch(accountListViewModelProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cuentas compartidas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Elegí qué cuentas quiere ver y usar el grupo familiar.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          accountsState.when(
            loading: () => const LinearProgressIndicator(),
            error: (_) => const SizedBox.shrink(),
            empty: () => Text(
              'No tenés cuentas registradas.',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            success: (accounts) => AppSearchableMultiSelector<AccountEntity>(
              items: accounts,
              idOf: (item) => item.id,
              labelOf: (item) => item.name,
              leadingOf: (item) => Icon(item.icon, color: colors.primary),
              values: group.sharedAccounts,
              hint: 'Buscar y seleccionar cuentas compartidas',
              searchHint: 'Buscar cuentas',
              onChanged: (selected) {
                final viewModel = ref.read(familyViewModelProvider.notifier);
                final selectedIds = selected.map((item) => item.id).toSet();
                for (final account in group.sharedAccounts) {
                  if (!selectedIds.contains(account.id)) {
                    viewModel.removeSharedAccount(account.id);
                  }
                }
                for (final account in selected) {
                  if (!group.sharedAccounts.any(
                    (item) => item.id == account.id,
                  )) {
                    viewModel.addSharedAccount(account.id);
                  }
                }
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Listo',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _AddFamilyMovementSheet extends ConsumerStatefulWidget {
  final FamilyGroupEntity group;
  final FamilyMemberEntity currentMember;
  const _AddFamilyMovementSheet({
    required this.group,
    required this.currentMember,
  });

  @override
  ConsumerState<_AddFamilyMovementSheet> createState() =>
      _AddFamilyMovementSheetState();
}

class _AddFamilyMovementSheetState
    extends ConsumerState<_AddFamilyMovementSheet> {
  FamilyMovementType _type = FamilyMovementType.expense;
  final _amount = TextEditingController();
  final _description = TextEditingController();
  CategoryEntity? _category;
  AccountEntity? _account;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final categoriesState = ref.watch(familyCategoriesProvider);
    _account ??= widget.group.sharedAccounts.first;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Añadir movimiento familiar',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _type = FamilyMovementType.expense),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _type == FamilyMovementType.expense
                              ? colors.error.withValues(alpha: 0.16)
                              : colors.surfaceElevated,
                          borderRadius: AppRadius.mdRadius,
                        ),
                        child: Center(
                          child: Text(
                            'Gasto',
                            style: TextStyle(
                              color: _type == FamilyMovementType.expense
                                  ? colors.error
                                  : colors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _type = FamilyMovementType.income),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _type == FamilyMovementType.income
                              ? colors.success.withValues(alpha: 0.16)
                              : colors.surfaceElevated,
                          borderRadius: AppRadius.mdRadius,
                        ),
                        child: Center(
                          child: Text(
                            'Ingreso',
                            style: TextStyle(
                              color: _type == FamilyMovementType.income
                                  ? colors.success
                                  : colors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Monto (Gs.)',
                controller: _amount,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Descripción',
                controller: _description,
                hint: 'Opcional',
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Categoría',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              categoriesState.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const SizedBox.shrink(),
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Text('No hay categorías familiares.');
                  }
                  _category ??= categories.first;
                  return AppSearchableSingleSelector<CategoryEntity>(
                    items: categories,
                    idOf: (item) => item.id,
                    labelOf: (item) => item.name,
                    leadingOf: (item) => Icon(item.icon, color: item.color),
                    value: _category,
                    hint: 'Seleccionar categoría',
                    searchHint: 'Buscar categorías',
                    onChanged: (value) => setState(() => _category = value),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Cuenta compartida',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              AppSearchableSingleSelector<AccountEntity>(
                items: widget.group.sharedAccounts,
                idOf: (item) => item.id,
                labelOf: (item) => item.name,
                leadingOf: (item) => Icon(item.icon, color: colors.primary),
                value: _account,
                hint: 'Seleccionar cuenta compartida',
                searchHint: 'Buscar cuentas compartidas',
                onChanged: (value) => setState(() => _account = value),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: TextStyle(color: colors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Guardar movimiento',
                onPressed: _category == null || _account == null
                    ? null
                    : () async {
                        final amount = double.tryParse(_amount.text) ?? 0;
                        if (amount <= 0) {
                          setState(() => _error = 'Ingresá un monto válido.');
                          return;
                        }
                        final entity = FamilyMovementEntity(
                          id: '',
                          type: _type,
                          amount: amount,
                          date: DateTime.now(),
                          category: _category!,
                          account: _account!,
                          description: _description.text.trim().isEmpty
                              ? _category!.name
                              : _description.text.trim(),
                          createdByMemberId: widget.currentMember.id,
                          createdByMemberName: widget.currentMember.name,
                        );
                        final error = await ref
                            .read(familyMovementListViewModelProvider.notifier)
                            .addMovement(entity);
                        if (error != null) {
                          setState(() => _error = error);
                          return;
                        }
                        if (context.mounted) Navigator.of(context).pop();
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyMovementList extends ConsumerWidget {
  const _FamilyMovementList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(familyMovementListViewModelProvider);
    final colors = context.colors;

    return state.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: LinearProgressIndicator(),
      ),
      error: (message) => AppErrorState(
        message: message,
        onRetry: ref.read(familyMovementListViewModelProvider.notifier).load,
      ),
      empty: () => AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Sin movimientos compartidos',
        message:
            'Los ingresos y gastos que registrés en la caja familiar aparecerán acá.',
      ),
      success: (movements) => Column(
        children: movements.map((m) {
          final isIncome = m.type == FamilyMovementType.income;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: m.category.color.withValues(alpha: 0.16),
                      borderRadius: AppRadius.mdRadius,
                    ),
                    child: Icon(
                      m.category.icon,
                      size: 18,
                      color: m.category.color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.description,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          'Por ${m.createdByMemberName} · ${DateFormatter.short(m.date)}',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isIncome ? '+' : '-'}${CurrencyFormatter.format(m.amount)}',
                    style: TextStyle(
                      color: isIncome ? colors.success : colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
