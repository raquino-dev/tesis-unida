import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme_extension.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/security_entity.dart';
import '../security_providers.dart';

Future<String?> requestOtpVerification(
  BuildContext context,
  WidgetRef ref, {
  required String reason,
}) async {
  final challenge = await ref
      .read(securityRepositoryProvider)
      .requestOtp(reason);
  if (!context.mounted) return null;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OtpVerificationDialog(challenge: challenge),
  );
}

class _OtpVerificationDialog extends ConsumerStatefulWidget {
  const _OtpVerificationDialog({required this.challenge});

  final OtpChallengeEntity challenge;

  @override
  ConsumerState<_OtpVerificationDialog> createState() =>
      _OtpVerificationDialogState();
}

class _OtpVerificationDialogState
    extends ConsumerState<_OtpVerificationDialog> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  late OtpChallengeEntity _challenge = widget.challenge;
  late Duration _remaining = _challenge.expiresAt.difference(DateTime.now());
  Timer? _timer;
  bool _loading = false;
  bool _resending = false;
  String? _error;

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
    _timer?.cancel();
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      final replacement = await ref
          .read(securityRepositoryProvider)
          .requestOtp(_challenge.reason);
      if (!mounted) return;
      _code.clear();
      setState(() {
        _challenge = replacement;
        _remaining = replacement.expiresAt.difference(DateTime.now());
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'No pudimos reenviar el código.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    if (_code.text.length != 6 || _loading || _remaining.isNegative) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final verificationId = await ref
          .read(securityRepositoryProvider)
          .validateOtp(_challenge.id, _code.text);
      ref.invalidate(securityEventsProvider);
      if (!mounted) return;
      if (verificationId != null) {
        Navigator.pop(context, verificationId);
      } else {
        setState(() => _error = 'El código ingresado no es válido.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'No pudimos verificar el código.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final media = MediaQuery.of(context);
    final code = _code.text;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              media.size.height - media.padding.top - media.viewInsets.bottom,
        ),
        child: Material(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textMuted.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Cerrar verificación',
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                Container(
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline_rounded,
                        size: 49,
                        color: colors.primary,
                      ),
                      Positioned(
                        right: 3,
                        bottom: 4,
                        child: CircleAvatar(
                          radius: 17,
                          backgroundColor: colors.primary,
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 17,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Verificación adicional',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresá el código de seis dígitos enviado a tu correo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 22),
                _InfoBanner(
                  icon: Icons.mail_outline_rounded,
                  children: [
                    Text(
                      'Enviado a ${_challenge.maskedDestination}',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_challenge.demoCode != null)
                      Text(
                        'Código de demostración: ${_challenge.demoCode}',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                  ],
                ),
                const SizedBox(height: 23),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Código OTP',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Semantics(
                  label: 'Código OTP de seis dígitos',
                  child: GestureDetector(
                    onTap: _focus.requestFocus,
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0,
                            child: TextField(
                              controller: _code,
                              focusNode: _focus,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.oneTimeCode],
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              onChanged: (_) => setState(() => _error = null),
                              onSubmitted: (_) => _verify(),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (var index = 0; index < 6; index++) ...[
                              if (index > 0) const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 57,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(
                                      color: index == code.length.clamp(0, 5)
                                          ? colors.primary
                                          : colors.border,
                                      width: index == code.length.clamp(0, 5)
                                          ? 1.5
                                          : 1,
                                    ),
                                  ),
                                  child: Text(
                                    index < code.length ? code[index] : '',
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _error!,
                      style: TextStyle(color: colors.error, fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 19,
                      color: colors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        _remaining.isNegative
                            ? 'Código vencido'
                            : 'Vence en ${_remaining.inMinutes}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _loading || _resending ? null : _resend,
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 20,
                        color: colors.primary,
                      ),
                      label: Text(
                        _resending ? 'Reenviando…' : 'Reenviar código',
                        style: TextStyle(color: colors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _InfoBanner(
                  icon: Icons.verified_user_outlined,
                  children: [
                    Text(
                      'Por tu seguridad, no compartas este código con nadie.',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                AppButton(
                  label: 'Verificar',
                  isLoading: _loading,
                  onPressed: code.length == 6 && !_remaining.isNegative
                      ? _verify
                      : null,
                ),
                const SizedBox(height: 9),
                TextButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.children});

  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 25, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
