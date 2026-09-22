import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/view_state.dart';
import '../../../accounts/domain/account_entity.dart';
import '../../../categories/domain/category_entity.dart';
import '../../../ocr/domain/ocr_repository.dart';
import '../../../ocr/presentation/viewmodels/ocr_viewmodel.dart';
import '../../domain/movement_entity.dart';
import 'movement_providers.dart';

class AddMovementViewModel extends StateNotifier<ViewState<MovementEntity>> {
  final Ref _ref;
  AddMovementViewModel(this._ref) : super(const ViewState.empty());

  Future<void> submit({
    String? existingId,
    required MovementType type,
    required double amount,
    required DateTime date,
    required List<CategoryEntity> categories,
    required AccountEntity account,
    String? creditCardId,
    CardOperation? cardOperation,
    required String description,
    bool hasAttachment = false,
    AttachmentType? attachmentType,
    OcrStatus? ocrStatus,
    String? attachmentPath,
    String? attachmentName,
    String? documentId,
  }) async {
    if (amount <= 0) {
      state = const ViewState.error('Ingresá un monto válido.');
      return;
    }
    if (categories.isEmpty) {
      state = const ViewState.error('Seleccioná al menos una categoría.');
      return;
    }
    state = const ViewState.loading();
    try {
      final repository = _ref.read(movementRepositoryProvider);
      var effectiveDocumentId = documentId;
      var effectiveOcrStatus = ocrStatus;
      if (hasAttachment &&
          effectiveDocumentId == null &&
          attachmentPath != null &&
          attachmentName != null) {
        final processed = await _ref
            .read(ocrRepositoryProvider)
            .processReceipt(
              _sourceFor(attachmentType),
              documentPath: attachmentPath,
              documentName: attachmentName,
            );
        effectiveDocumentId = processed.documentId;
        effectiveOcrStatus = processed.status;
      }
      final movement = MovementEntity(
        id: existingId ?? '',
        type: type,
        amount: amount,
        date: date,
        categories: categories,
        description: description.isEmpty ? categories.first.name : description,
        account: account,
        creditCardId: creditCardId,
        cardOperation: cardOperation,
        hasAttachment: hasAttachment,
        attachmentType: attachmentType,
        ocrStatus: effectiveOcrStatus,
        attachmentPath: attachmentPath,
        attachmentName: attachmentName,
        documentId: effectiveDocumentId,
      );
      final result = existingId == null
          ? await repository.addMovement(movement)
          : await repository.updateMovement(movement);
      state = ViewState.success(result);
    } catch (e) {
      state = const ViewState.error(
        'No pudimos guardar el movimiento. Intentá nuevamente.',
      );
    }
  }

  void reset() => state = const ViewState.empty();

  OcrSource _sourceFor(AttachmentType? type) => switch (type) {
    AttachmentType.pdf => OcrSource.pdf,
    AttachmentType.xml => OcrSource.xml,
    _ => OcrSource.gallery,
  };
}

final addMovementViewModelProvider =
    StateNotifierProvider.autoDispose<
      AddMovementViewModel,
      ViewState<MovementEntity>
    >((ref) => AddMovementViewModel(ref));
