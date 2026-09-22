import '../../../accounts/domain/account_entity.dart';
import '../../../categories/domain/category_entity.dart';
import '../../domain/movement_entity.dart';

class MovementModel {
  final String id;
  final MovementType type;
  final double amount;
  final DateTime date;
  final List<String> categoryIds;
  final String description;
  final String accountId;
  final String? creditCardId;
  final CardOperation? cardOperation;
  final String? transferId;
  final bool hasAttachment;
  final AttachmentType? attachmentType;
  final OcrStatus? ocrStatus;
  final String? attachmentPath;
  final String? attachmentName;
  final String? documentId;

  const MovementModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.categoryIds,
    required this.description,
    required this.accountId,
    this.creditCardId,
    this.cardOperation,
    this.transferId,
    this.hasAttachment = false,
    this.attachmentType,
    this.ocrStatus,
    this.attachmentPath,
    this.attachmentName,
    this.documentId,
  });

  factory MovementModel.fromMock(Map<String, dynamic> json) {
    return MovementModel(
      id: json['id'] as String,
      type: json['type'] == 'income'
          ? MovementType.income
          : MovementType.expense,
      amount: json['amount'] as double,
      date: json['date'] as DateTime,
      categoryIds: List<String>.from(json['categoryIds'] as List),
      description: json['description'] as String,
      accountId: json['accountId'] as String,
      creditCardId: json['creditCardId'] as String?,
      cardOperation: cardOperationFromString(json['cardOperation'] as String?),
      transferId: json['transferId'] as String?,
      hasAttachment: json['hasAttachment'] as bool? ?? false,
      attachmentType: attachmentTypeFromString(
        json['attachmentType'] as String?,
      ),
      ocrStatus: ocrStatusFromString(json['ocrStatus'] as String?),
      attachmentPath: json['attachmentPath'] as String?,
      attachmentName: json['attachmentName'] as String?,
      documentId: json['documentId'] as String?,
    );
  }

  MovementEntity toEntity({
    required List<CategoryEntity> categories,
    required AccountEntity account,
  }) {
    return MovementEntity(
      id: id,
      type: type,
      amount: amount,
      date: date,
      categories: categories,
      description: description,
      account: account,
      creditCardId: creditCardId,
      cardOperation: cardOperation,
      transferId: transferId,
      hasAttachment: hasAttachment,
      attachmentType: attachmentType,
      ocrStatus: ocrStatus,
      attachmentPath: attachmentPath,
      attachmentName: attachmentName,
      documentId: documentId,
    );
  }
}
