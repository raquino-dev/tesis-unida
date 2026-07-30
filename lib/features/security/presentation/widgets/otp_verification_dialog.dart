import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/security_entity.dart';
import '../security_providers.dart';

Future<bool> requestOtpVerification(
  BuildContext context,
  WidgetRef ref, {
  required String reason,
}) async {
  final challenge = await ref
      .read(securityRepositoryProvider)
      .requestOtp(reason);
  if (!context.mounted) return false;
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _OtpVerificationDialog(challenge: challenge),
      ) ??
      false;
}

class _OtpVerificationDialog extends ConsumerStatefulWidget {
  final OtpChallengeEntity challenge;
  const _OtpVerificationDialog({required this.challenge});

  @override
  ConsumerState<_OtpVerificationDialog> createState() =>
      _OtpVerificationDialogState();
}

class _OtpVerificationDialogState
    extends ConsumerState<_OtpVerificationDialog> {
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;
  late OtpChallengeEntity _challenge = widget.challenge;
  late Duration _remaining = _challenge.expiresAt.difference(DateTime.now());
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(
          () => _remaining = _challenge.expiresAt.difference(DateTime.now()),
        );
      }
    });
  }

  @override
  void dispose() {
    _code.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verificación adicional'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Ingresá el código de seis dígitos enviado a tu correo.'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Enviado a ${_challenge.maskedDestination}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Código de demostración: ${_challenge.demoCode}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            _remaining.isNegative
                ? 'Código vencido'
                : 'Vence en ${_remaining.inMinutes}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Código OTP',
            controller: _code,
            keyboardType: TextInputType.number,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading
              ? null
              : () async {
                  final replacement = await ref
                      .read(securityRepositoryProvider)
                      .requestOtp('Reenvío de código');
                  if (!mounted) return;
                  setState(() {
                    _challenge = replacement;
                    _remaining = replacement.expiresAt.difference(
                      DateTime.now(),
                    );
                    _error = null;
                  });
                },
          child: const Text('Reenviar'),
        ),
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        SizedBox(
          width: 130,
          child: AppButton(
            label: 'Verificar',
            isLoading: _loading,
            onPressed: _loading
                ? null
                : () async {
                    setState(() => _loading = true);
                    final valid = await ref
                        .read(securityRepositoryProvider)
                        .validateOtp(_challenge.id, _code.text.trim());
                    ref.invalidate(securityEventsProvider);
                    if (!mounted) return;
                    if (valid) {
                      Navigator.pop(this.context, true);
                    } else {
                      setState(() {
                        _loading = false;
                        _error = 'El código ingresado no es válido.';
                      });
                    }
                  },
          ),
        ),
      ],
    );
  }
}
