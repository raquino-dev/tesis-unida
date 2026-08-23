import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/services/pilot_local_store.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/api_pilot_instrument_repository.dart';
import 'pilot_consent_provider.dart';
import 'pilot_instrument_provider.dart';

class PilotCenterScreen extends ConsumerStatefulWidget {
  const PilotCenterScreen({super.key});

  @override
  ConsumerState<PilotCenterScreen> createState() => _PilotCenterScreenState();
}

class _PilotCenterScreenState extends ConsumerState<PilotCenterScreen> {
  bool _consentChecked = false;
  bool _checkingConsent = true;
  bool _savingConsent = false;
  bool _loadingInstruments = false;
  String? _consentError;
  String? _instrumentError;
  PilotInstrument? _preInstrument;
  PilotInstrument? _postInstrument;
  final _feedback = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    setState(() {
      _checkingConsent = true;
      _consentError = null;
    });
    try {
      final repository = ref.read(pilotConsentRepositoryProvider);
      final accepted = repository == null
          ? PilotLocalStore.consentAccepted
          : await repository.hasActiveConsent();
      if (accepted) await PilotLocalStore.acceptConsent();
      if (!mounted) return;
      setState(() => _checkingConsent = false);
      if (accepted) await _loadInstruments();
    } on AppFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _checkingConsent = false;
        _consentError = appErrorMessage(error);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checkingConsent = false;
        _consentError = 'No pudimos verificar tu consentimiento registrado.';
      });
    }
  }

  Future<void> _loadInstruments() async {
    final repository = ref.read(pilotInstrumentRepositoryProvider);
    if (repository == null) return;
    setState(() {
      _loadingInstruments = true;
      _instrumentError = null;
    });
    try {
      final instruments = await Future.wait([
        repository.get('preuso'),
        repository.get('postuso'),
      ]);
      if (!mounted) return;
      setState(() {
        _preInstrument = instruments[0];
        _postInstrument = instruments[1];
      });
    } on AppFailure catch (error) {
      if (!mounted) return;
      setState(() => _instrumentError = appErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      setState(
        () =>
            _instrumentError = 'No pudimos cargar los instrumentos del piloto.',
      );
    } finally {
      if (mounted) setState(() => _loadingInstruments = false);
    }
  }

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
          if (_checkingConsent)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_consentError != null)
            _consentErrorCard(context)
          else if (!consent)
            _consentCard(context)
          else
            ..._instrumentContent(context),
        ],
      ),
    );
  }

  List<Widget> _instrumentContent(BuildContext context) => [
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
    if (_loadingInstruments)
      const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      )
    else if (_instrumentError != null)
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_instrumentError!),
            const SizedBox(height: AppSpacing.sm),
            AppButton(label: 'Reintentar', onPressed: _loadInstruments),
          ],
        ),
      )
    else if (_preInstrument != null && _postInstrument != null) ...[
      _surveyCard(context, _preInstrument!),
      const SizedBox(height: AppSpacing.sm),
      _surveyCard(context, _postInstrument!),
      const SizedBox(height: AppSpacing.xs),
      Text(
        'Las preguntas y su versión se obtienen del servidor. Las respuestas ya enviadas no se modifican.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ] else
      const AppCard(
        child: Text(
          'Los instrumentos se mostrarán cuando se habilite la conexión con el servidor.',
        ),
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
                    content: Text('Gracias. Tu comentario quedó registrado.'),
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
  ];

  Widget _consentCard(BuildContext context) => AppCard(
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
          label: _savingConsent ? 'Registrando…' : 'Aceptar y continuar',
          onPressed: !_consentChecked || _savingConsent ? null : _acceptConsent,
        ),
      ],
    ),
  );

  Future<void> _acceptConsent() async {
    setState(() => _savingConsent = true);
    try {
      await ref.read(pilotConsentRepositoryProvider)?.accept();
      await PilotLocalStore.acceptConsent();
      await PilotLocalStore.recordMetric('pilot_consent_accepted');
      if (!mounted) return;
      setState(() {});
      await _loadInstruments();
    } on AppFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(appErrorMessage(error))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos registrar el consentimiento. Intentá nuevamente.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingConsent = false);
    }
  }

  Widget _consentErrorCard(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.cloud_off_outlined),
        const SizedBox(height: AppSpacing.sm),
        Text(_consentError!, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.sm),
        AppButton(label: 'Reintentar', onPressed: _loadConsent),
      ],
    ),
  );

  Widget _surveyCard(
    BuildContext context,
    PilotInstrument instrument,
  ) => AppCard(
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        instrument.completed
            ? Icons.check_circle_outline_rounded
            : Icons.assignment_outlined,
      ),
      title: Text(instrument.title),
      subtitle: Text(
        instrument.completed
            ? 'Completada · versión ${instrument.version}'
            : '${instrument.questions.length} preguntas · versión ${instrument.version}',
      ),
      trailing: instrument.completed
          ? null
          : TextButton(
              onPressed: () => _openSurvey(instrument),
              child: const Text('Responder'),
            ),
    ),
  );

  Future<void> _openSurvey(PilotInstrument instrument) async {
    final result = await showModalBottomSheet<List<PilotInstrumentAnswer>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PilotSurveySheet(instrument: instrument),
    );
    if (result == null || !mounted) return;
    try {
      await ref
          .read(pilotInstrumentRepositoryProvider)
          ?.submit(instrument.code, result);
      await PilotLocalStore.recordMetric(
        '${instrument.code}_survey_completed',
        data: {'version': instrument.version},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Respuestas registradas correctamente.'),
          ),
        );
        await _loadInstruments();
      }
    } on AppFailure catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(appErrorMessage(error))));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pudimos guardar tus respuestas. Intentá nuevamente.',
            ),
          ),
        );
      }
    }
  }
}

class _PilotSurveySheet extends StatefulWidget {
  const _PilotSurveySheet({required this.instrument});
  final PilotInstrument instrument;

  @override
  State<_PilotSurveySheet> createState() => _PilotSurveySheetState();
}

class _PilotSurveySheetState extends State<_PilotSurveySheet> {
  final Map<String, int> _scaleAnswers = {};
  final Map<String, TextEditingController> _textAnswers = {};
  bool _showValidation = false;

  @override
  void initState() {
    super.initState();
    for (final question in widget.instrument.questions) {
      if (question.isScale) _scaleAnswers[question.id] = question.minimum ?? 1;
      if (!question.isScale) {
        _textAnswers[question.id] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _textAnswers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isComplete => widget.instrument.questions.every((question) {
    if (!question.required) return true;
    return question.isScale ||
        (_textAnswers[question.id]?.text.trim().isNotEmpty ?? false);
  });

  @override
  Widget build(BuildContext context) => SafeArea(
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
              widget.instrument.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (widget.instrument.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(widget.instrument.description),
            ],
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'En las escalas: 1 = totalmente en desacuerdo · 5 = totalmente de acuerdo',
            ),
            const SizedBox(height: AppSpacing.md),
            for (final question in widget.instrument.questions) ...[
              Text(
                '${question.order}. ${question.text}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (question.isScale)
                Slider(
                  value: (_scaleAnswers[question.id] ?? question.minimum ?? 1)
                      .toDouble(),
                  min: (question.minimum ?? 1).toDouble(),
                  max: (question.maximum ?? 5).toDouble(),
                  divisions: (question.maximum ?? 5) - (question.minimum ?? 1),
                  label: '${_scaleAnswers[question.id]}',
                  onChanged: (value) => setState(
                    () => _scaleAnswers[question.id] = value.round(),
                  ),
                )
              else
                TextField(
                  controller: _textAnswers[question.id],
                  minLines: 2,
                  maxLines: 4,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Escribí tu respuesta',
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (_showValidation && !_isComplete)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  'Completá todas las preguntas obligatorias.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            AppButton(
              label: 'Guardar respuestas',
              onPressed: () {
                if (!_isComplete) {
                  setState(() => _showValidation = true);
                  return;
                }
                Navigator.pop(
                  context,
                  widget.instrument.questions
                      .map(
                        (question) => PilotInstrumentAnswer(
                          questionId: question.id,
                          scaleValue: question.isScale
                              ? _scaleAnswers[question.id]
                              : null,
                          textValue: question.isScale
                              ? null
                              : _textAnswers[question.id]?.text.trim(),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
