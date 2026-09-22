import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/view_state.dart';
import '../../../../core/config/app_environment.dart';
import '../../../../core/network/api_providers.dart';
import '../../data/api_ocr_repository.dart';
import '../../data/mock_ocr_repository.dart';
import '../../domain/ocr_repository.dart';
import '../../domain/ocr_result_entity.dart';
import '../../../../core/services/attachment_picker_service.dart';
import '../../../../core/services/pilot_local_store.dart';

final ocrRepositoryProvider = Provider<OcrRepository>((ref) {
  if (AppEnvironment.useApi) {
    return ApiOcrRepository(ref.watch(apiClientProvider));
  }
  return MockOcrRepository();
});

class OcrViewModel extends StateNotifier<ViewState<OcrResultEntity>> {
  final Ref _ref;
  int _operationId = 0;
  OcrViewModel(this._ref) : super(const ViewState.empty());

  Future<void> scan(OcrSource source) async {
    final operationId = ++_operationId;
    try {
      final startedAt = DateTime.now();
      final selected = await AttachmentPickerService.pick(source);
      if (!mounted || operationId != _operationId || selected == null) return;
      state = const ViewState.loading();
      final result = await _ref
          .read(ocrRepositoryProvider)
          .processReceipt(
            source,
            documentPath: selected.path,
            documentName: selected.name,
          );
      if (!mounted || operationId != _operationId) return;
      await PilotLocalStore.registerOcrUse();
      await PilotLocalStore.recordMetric(
        'ocr_processed',
        data: {
          'source': source.name,
          'status': result.status.name,
          'size': selected.size,
          'durationSeconds': DateTime.now().difference(startedAt).inSeconds,
        },
      );
      if (!mounted || operationId != _operationId) return;
      state = ViewState.success(result);
    } on AppFailure catch (error) {
      if (mounted && operationId == _operationId) {
        state = ViewState.error(error.message);
      }
    } on FormatException catch (error) {
      if (mounted && operationId == _operationId) {
        state = ViewState.error(error.message);
      }
    } catch (_) {
      if (mounted && operationId == _operationId) {
        state = const ViewState.error(
          'No pudimos abrir o procesar el comprobante. Revisá los permisos e intentá nuevamente.',
        );
      }
    }
  }

  void reset() {
    _operationId++;
    state = const ViewState.empty();
  }
}

final ocrViewModelProvider =
    StateNotifierProvider.autoDispose<OcrViewModel, ViewState<OcrResultEntity>>(
      (ref) => OcrViewModel(ref),
    );
