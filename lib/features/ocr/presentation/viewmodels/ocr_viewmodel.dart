import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  OcrViewModel(this._ref) : super(const ViewState.empty());

  Future<void> scan(OcrSource source) async {
    try {
      final startedAt = DateTime.now();
      final selected = await AttachmentPickerService.pick(source);
      if (selected == null) return;
      state = const ViewState.loading();
      final result = await _ref
          .read(ocrRepositoryProvider)
          .processReceipt(
            source,
            documentPath: selected.path,
            documentName: selected.name,
          );
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
      state = ViewState.success(result);
    } on FormatException catch (error) {
      state = ViewState.error(error.message);
    } catch (_) {
      state = const ViewState.error(
        'No pudimos abrir o procesar el comprobante. Revisá los permisos e intentá nuevamente.',
      );
    }
  }

  void reset() => state = const ViewState.empty();
}

final ocrViewModelProvider =
    StateNotifierProvider.autoDispose<OcrViewModel, ViewState<OcrResultEntity>>(
      (ref) => OcrViewModel(ref),
    );
