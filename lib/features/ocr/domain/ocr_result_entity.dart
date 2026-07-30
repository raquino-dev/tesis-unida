import '../../movements/domain/movement_entity.dart';
import 'ocr_repository.dart';

class OcrResultEntity {
  final double amount;
  final DateTime date;
  final String merchant;
  final String suggestedCategoryId;
  final double confidence;
  final OcrStatus status;
  final OcrSource source;
  final String documentReference;
  final String? documentPath;
  final String? documentName;

  const OcrResultEntity({
    required this.amount,
    required this.date,
    required this.merchant,
    required this.suggestedCategoryId,
    required this.confidence,
    required this.status,
    required this.source,
    required this.documentReference,
    this.documentPath,
    this.documentName,
  });
}
