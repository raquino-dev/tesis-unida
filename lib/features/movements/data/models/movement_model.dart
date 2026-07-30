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
  final bool hasAttachment;
  final AttachmentType? attachmentType;
  final OcrStatus? ocrStatus;
  final String? attachmentPath;
  final String? attachmentName;

  const MovementModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.categoryIds,
    required this.description,
    required this.accountId,
    this.hasAttachment = false,
    this.attachmentType,
    this.ocrStatus,
    this.attachmentPath,
    this.attachmentName,
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
      hasAttachment: json['hasAttachment'] as bool? ?? false,
      attachmentType: attachmentTypeFromString(
        json['attachmentType'] as String?,
      ),
      ocrStatus: ocrStatusFromString(json['ocrStatus'] as String?),
      attachmentPath: json['attachmentPath'] as String?,
      attachmentName: json['attachmentName'] as String?,
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
      hasAttachment: hasAttachment,
      attachmentType: attachmentType,
      ocrStatus: ocrStatus,
      attachmentPath: attachmentPath,
      attachmentName: attachmentName,
    );
  }
}
