import '../../accounts/domain/account_entity.dart';
import '../../categories/domain/category_entity.dart';

enum MovementType { expense, income }

enum OcrStatus { pending, processing, success, incomplete, failed }

enum AttachmentType { image, pdf, xml }

OcrStatus? ocrStatusFromString(String? value) {
  switch (value) {
    case 'pendiente':
      return OcrStatus.pending;
    case 'procesando':
      return OcrStatus.processing;
    case 'exitoso':
      return OcrStatus.success;
    case 'incompleto':
      return OcrStatus.incomplete;
    case 'fallido':
      return OcrStatus.failed;
    default:
      return null;
  }
}

AttachmentType? attachmentTypeFromString(String? value) {
  switch (value) {
    case 'image':
      return AttachmentType.image;
    case 'pdf':
      return AttachmentType.pdf;
    case 'xml':
      return AttachmentType.xml;
    default:
      return null;
  }
}

class MovementEntity {
  final String id;
  final MovementType type;
  final double amount;
  final DateTime date;
  final List<CategoryEntity> categories;
  final String description;
  final AccountEntity account;
  final bool hasAttachment;
  final AttachmentType? attachmentType;
  final OcrStatus? ocrStatus;
  final String? attachmentPath;
  final String? attachmentName;

  /// Id del registro recurrente que originó este movimiento, cuando aplica.
  final String? recurringSourceId;

  const MovementEntity({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.categories,
    required this.description,
    required this.account,
    this.hasAttachment = false,
    this.attachmentType,
    this.ocrStatus,
    this.attachmentPath,
    this.attachmentName,
    this.recurringSourceId,
  });

  /// Primera categoría, útil para vistas compactas (tarjetas, íconos).
  CategoryEntity get primaryCategory => categories.first;

  MovementEntity copyWith({
    MovementType? type,
    double? amount,
    DateTime? date,
    List<CategoryEntity>? categories,
    String? description,
    AccountEntity? account,
    bool? hasAttachment,
    AttachmentType? attachmentType,
    OcrStatus? ocrStatus,
    String? attachmentPath,
    String? attachmentName,
    String? recurringSourceId,
  }) {
    return MovementEntity(
      id: id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categories: categories ?? this.categories,
      description: description ?? this.description,
      account: account ?? this.account,
      hasAttachment: hasAttachment ?? this.hasAttachment,
      attachmentType: attachmentType ?? this.attachmentType,
      ocrStatus: ocrStatus ?? this.ocrStatus,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      attachmentName: attachmentName ?? this.attachmentName,
      recurringSourceId: recurringSourceId ?? this.recurringSourceId,
    );
  }
}
