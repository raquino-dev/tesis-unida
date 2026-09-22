import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/pilot_local_store.dart';
import '../../../../core/widgets/finanza_mark.dart';
import '../widgets/onboarding_illustration.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.illustration,
  });

  final String title;
  final String description;
  final OnboardingIllustrationVariant illustration;
}

const _pages = [
  _OnboardingPage(
    title: 'Tus finanzas,\nen un solo lugar',
    description:
        'Registrá tus gastos e ingresos y entendé tu situación financiera en segundos.',
    illustration: OnboardingIllustrationVariant.overview,
  ),
  _OnboardingPage(
    title: 'Rápido y sin fricción',
    description:
        'Añadí un gasto en menos de 10 segundos o escaneá tu factura y dejá que el detalle se complete solo.',
    illustration: OnboardingIllustrationVariant.speed,
  ),
  _OnboardingPage(
    title: 'Claridad, no juicios',
    description:
        'Tu score financiero y tus alertas son una guía para mejorar, nunca una calificación personal.',
    illustration: OnboardingIllustrationVariant.clarity,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish(String route) async {
    await PilotLocalStore.completeOnboarding();
    if (mounted) context.go(route);
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish(AppRoutes.register);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 20, 0),
              child: Row(
                children: [
                  const FinanzaMark(size: 43),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Finanza',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Pequeños hábitos, grandes logros.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSecondaryLight,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _finish(AppRoutes.login),
                    child: const Text(
                      'Omitir',
                      style: TextStyle(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _index = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return LayoutBuilder(
                    builder: (context, constraints) => Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: OnboardingIllustration(
                              variant: page.illustration,
                              height: (constraints.maxHeight * 0.64).clamp(
                                220.0,
                                325.0,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 29,
                              height: 1.12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            page.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondaryLight,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final selected = index == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.emerald
                        : const Color(0xFFD4E5E1),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: _ContinueButton(
                label: _index == _pages.length - 1
                    ? 'Crear cuenta'
                    : 'Continuar',
                onPressed: _next,
              ),
            ),
            TextButton(
              onPressed: () => _finish(AppRoutes.login),
              child: const Text(
                'Ya tengo una cuenta',
                style: TextStyle(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(99),
      child: Ink(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.emerald, AppColors.forest],
          ),
          borderRadius: BorderRadius.circular(99),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(99),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 20),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 21,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
