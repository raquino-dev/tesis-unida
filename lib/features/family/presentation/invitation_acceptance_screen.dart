import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/services/pilot_local_store.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'family_providers.dart';

class InvitationAcceptanceScreen extends ConsumerStatefulWidget {
  final String? initialCode;
  const InvitationAcceptanceScreen({super.key, this.initialCode});

  @override
  ConsumerState<InvitationAcceptanceScreen> createState() =>
      _InvitationAcceptanceScreenState();
}

class _InvitationAcceptanceScreenState
    extends ConsumerState<InvitationAcceptanceScreen> {
  late final _code = TextEditingController(text: widget.initialCode ?? '');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(familyRepositoryProvider)
          .acceptInvitation(_code.text.trim());
      await ref.read(familyViewModelProvider.notifier).load();
      ref.invalidate(familyInvitationsProvider);
      await PilotLocalStore.recordMetric('family_invitation_accepted');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitación aceptada. Ya formás parte del grupo.'),
        ),
      );
      context.go(AppRoutes.family);
    } on AppFailure catch (error) {
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aceptar invitación')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Icon(Icons.group_add_outlined, size: 72),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Ingresá el código de seis dígitos enviado por el administrador.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'Código de invitación',
            controller: _code,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Aceptar invitación',
            isLoading: _loading,
            onPressed: _loading || _code.text.trim().length != 6
                ? null
                : _accept,
          ),
        ],
      ),
    );
  }
}
