import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_theme_extension.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/services/pilot_local_store.dart';
import '../widgets/onboarding_illustration.dart';

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final OnboardingIllustrationVariant illustration;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.illustration,
  });
}

const _pages = [
  _OnboardingPage(
    icon: Icons.auto_graph_rounded,
    title: 'Tus finanzas, en un solo lugar',
    description:
        'Registrá tus gastos e ingresos y entendé tu situación financiera en segundos.',
    accent: AppColors.scampi,
    illustration: OnboardingIllustrationVariant.overview,
  ),
  _OnboardingPage(
    icon: Icons.bolt_rounded,
    title: 'Rápido y sin fricción',
    description:
        'Añadí un gasto en menos de 10 segundos o escaneá tu factura y dejá que el detalle se complete solo.',
    accent: AppColors.comet,
    illustration: OnboardingIllustrationVariant.speed,
  ),
  _OnboardingPage(
    icon: Icons.shield_moon_rounded,
    title: 'Claridad, no juicios',
    description:
        'Tu score financiero y tus alertas son una guía para mejorar, nunca una calificación personal.',
    accent: AppColors.scampi,
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
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: TextButton(
                  onPressed: () => _finish(AppRoutes.login),
                  child: const Text('Omitir'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) {
                  final page = _pages[i];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSpacing.md),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            OnboardingIllustration(
                              variant: page.illustration,
                              accent: page.accent,
                              height: 190,
                            ),
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.surface,
                                border: Border.all(
                                  color: page.accent.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                page.icon,
                                size: 42,
                                color: page.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? colors.primary : colors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  AppButton(
                    label: _index == _pages.length - 1
                        ? 'Crear cuenta'
                        : 'Continuar',
                    onPressed: _next,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => _finish(AppRoutes.login),
                    child: const Text('Ya tengo una cuenta'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
