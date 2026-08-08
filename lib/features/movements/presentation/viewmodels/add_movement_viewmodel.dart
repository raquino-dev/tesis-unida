import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/view_state.dart';
import '../../../accounts/domain/account_entity.dart';
import '../../../categories/domain/category_entity.dart';
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
      final movement = MovementEntity(
        id: existingId ?? '',
        type: type,
        amount: amount,
        date: date,
        categories: categories,
        description: description.isEmpty ? categories.first.name : description,
        account: account,
        hasAttachment: hasAttachment,
        attachmentType: attachmentType,
        ocrStatus: ocrStatus,
        attachmentPath: attachmentPath,
        attachmentName: attachmentName,
        documentId: documentId,
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
}

final addMovementViewModelProvider =
    StateNotifierProvider.autoDispose<
      AddMovementViewModel,
      ViewState<MovementEntity>
    >((ref) => AddMovementViewModel(ref));
