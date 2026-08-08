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
  final String? documentId;
  final String? processingId;
  final int processingVersion;
  final List<String> warnings;

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
    this.documentId,
    this.processingId,
    this.processingVersion = 1,
    this.warnings = const [],
  });

  OcrResultEntity copyWith({
    double? amount,
    DateTime? date,
    String? merchant,
    String? suggestedCategoryId,
    double? confidence,
    OcrStatus? status,
    int? processingVersion,
    List<String>? warnings,
  }) => OcrResultEntity(
    amount: amount ?? this.amount,
    date: date ?? this.date,
    merchant: merchant ?? this.merchant,
    suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
    confidence: confidence ?? this.confidence,
    status: status ?? this.status,
    source: source,
    documentReference: documentReference,
    documentPath: documentPath,
    documentName: documentName,
    documentId: documentId,
    processingId: processingId,
    processingVersion: processingVersion ?? this.processingVersion,
    warnings: warnings ?? this.warnings,
  );
}
