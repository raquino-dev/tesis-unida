import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/services/pilot_local_store.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';

class PilotCenterScreen extends StatefulWidget {
  const PilotCenterScreen({super.key});

  @override
  State<PilotCenterScreen> createState() => _PilotCenterScreenState();
}

class _PilotCenterScreenState extends State<PilotCenterScreen> {
  bool _consentChecked = false;
  final _feedback = TextEditingController();

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consent = PilotLocalStore.consentAccepted;
    return Scaffold(
      appBar: AppBar(title: const Text('Centro del piloto')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Prueba piloto · Asunción 2026',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Este espacio registra únicamente información necesaria para evaluar facilidad de uso, utilidad percibida, seguridad y tiempo de registro.',
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!consent)
            _consentCard(context)
          else ...[
            const AppCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.verified_user_outlined),
                title: Text('Consentimiento registrado'),
                subtitle: Text(
                  'Podés retirarte de la prueba en cualquier momento contactando al investigador.',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _surveyCard(
              context,
              title: 'Encuesta inicial',
              completed: PilotLocalStore.preSurveyCompleted,
              onStart: () => _openSurvey(context, isPost: false),
            ),
            const SizedBox(height: AppSpacing.sm),
            _surveyCard(
              context,
              title: 'Encuesta final',
              completed: PilotLocalStore.postSurveyCompleted,
              onStart: () => _openSurvey(context, isPost: true),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enviar comentario',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    label: '¿Qué te resultó difícil o útil?',
                    controller: _feedback,
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Guardar comentario',
                    onPressed: () async {
                      if (_feedback.text.trim().isEmpty) return;
                      await PilotLocalStore.recordMetric(
                        'pilot_feedback',
                        data: {'comment': _feedback.text.trim()},
                      );
                      _feedback.clear();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Gracias. Tu comentario quedó registrado.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Continuar a la aplicación',
              onPressed: () => context.go(AppRoutes.dashboard),
            ),
          ],
        ],
      ),
    );
  }

  Widget _consentCard(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consentimiento informado',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Acepto participar voluntariamente en una prueba académica con diez usuarios. Comprendo que se registrarán métricas de uso y respuestas de encuesta, que no se realizarán transferencias bancarias reales y que puedo abandonar la evaluación.',
          ),
          const SizedBox(height: AppSpacing.md),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _consentChecked,
            onChanged: (value) =>
                setState(() => _consentChecked = value ?? false),
            title: const Text('Leí la información y deseo participar'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          AppButton(
            label: 'Aceptar y continuar',
            onPressed: !_consentChecked
                ? null
                : () async {
                    await PilotLocalStore.acceptConsent();
                    await PilotLocalStore.recordMetric(
                      'pilot_consent_accepted',
                    );
                    if (mounted) setState(() {});
                  },
          ),
        ],
      ),
    );
  }

  Widget _surveyCard(
    BuildContext context, {
    required String title,
    required bool completed,
    required VoidCallback onStart,
  }) {
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          completed
              ? Icons.check_circle_outline_rounded
              : Icons.assignment_outlined,
        ),
        title: Text(title),
        subtitle: Text(
          completed ? 'Completada' : 'Cinco preguntas · menos de dos minutos',
        ),
        trailing: completed
            ? null
            : TextButton(onPressed: onStart, child: const Text('Responder')),
      ),
    );
  }

  Future<void> _openSurvey(BuildContext context, {required bool isPost}) async {
    final result = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PilotSurveySheet(isPost: isPost),
    );
    if (result == null) return;
    await PilotLocalStore.recordMetric(
      isPost ? 'post_survey_completed' : 'pre_survey_completed',
      data: {
        'control': result[0],
        'facilidad': result[1],
        'utilidad': result[2],
        'seguridad': result[3],
        'aceptacion': result[4],
      },
    );
    if (isPost) {
      await PilotLocalStore.completePostSurvey();
    } else {
      await PilotLocalStore.completePreSurvey();
    }
    if (mounted) setState(() {});
  }
}

class _PilotSurveySheet extends StatefulWidget {
  final bool isPost;
  const _PilotSurveySheet({required this.isPost});

  @override
  State<_PilotSurveySheet> createState() => _PilotSurveySheetState();
}

class _PilotSurveySheetState extends State<_PilotSurveySheet> {
  final _answers = List<int>.filled(5, 3);
  static const _questions = [
    'Siento que tengo control sobre mis gastos.',
    'Registrar un gasto me resulta fácil.',
    'La aplicación me parece útil para organizarme.',
    'Me siento seguro utilizando la aplicación.',
    'Usaría esta solución con frecuencia.',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isPost ? 'Encuesta final' : 'Encuesta inicial',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Text(
                '1 = totalmente en desacuerdo · 5 = totalmente de acuerdo',
              ),
              const SizedBox(height: AppSpacing.md),
              for (var index = 0; index < _questions.length; index++) ...[
                Text(_questions[index]),
                Slider(
                  value: _answers[index].toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '${_answers[index]}',
                  onChanged: (value) =>
                      setState(() => _answers[index] = value.round()),
                ),
              ],
              AppButton(
                label: 'Guardar respuestas',
                onPressed: () => Navigator.pop(context, _answers),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
