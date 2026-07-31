import 'dart:math';
import '../../movements/domain/movement_entity.dart';
import '../domain/ocr_repository.dart';
import '../domain/ocr_result_entity.dart';

class MockOcrRepository implements OcrRepository {
  final _random = Random();

  final _merchants = [
    'Supermercado San Roque',
    'Farmacia Catedral',
    'Estación de servicio Copetrol',
    'Restaurante La Terraza',
  ];

  @override
  Future<OcrResultEntity> processReceipt(
    OcrSource source, {
    String? documentPath,
    String? documentName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 2200));

    if (source == OcrSource.xml) {
      return OcrResultEntity(
        amount: 385000,
        date: DateTime.now().subtract(const Duration(days: 1)),
        merchant: 'Comprobante electrónico SIFEN 001-001-0001234',
        suggestedCategoryId: 'cat_servicios',
        confidence: 0.99,
        status: OcrStatus.success,
        source: source,
        documentReference:
            'CDC-DEMO-01800123456789012345678901234567890123456789',
        documentPath: documentPath,
        documentName: documentName,
      );
    }

    final outcome = _random.nextDouble();
    final merchant = _merchants[_random.nextInt(_merchants.length)];
    final amount = 30000 + _random.nextInt(400000).toDouble();

    if (outcome < 0.12) {
      return OcrResultEntity(
        amount: 0,
        date: DateTime.now(),
        merchant: '',
        suggestedCategoryId: 'cat_otros',
        confidence: 0,
        status: OcrStatus.failed,
        source: source,
        documentReference: source == OcrSource.pdf
            ? 'factura_demo.pdf'
            : 'imagen_demo.jpg',
        documentPath: documentPath,
        documentName: documentName,
      );
    }
    if (outcome < 0.3) {
      return OcrResultEntity(
        amount: amount,
        date: DateTime.now(),
        merchant: merchant,
        suggestedCategoryId: 'cat_alimentacion',
        confidence: 0.52,
        status: OcrStatus.incomplete,
        source: source,
        documentReference: source == OcrSource.pdf
            ? 'factura_demo.pdf'
            : 'imagen_demo.jpg',
        documentPath: documentPath,
        documentName: documentName,
      );
    }
    return OcrResultEntity(
      amount: amount,
      date: DateTime.now(),
      merchant: merchant,
      suggestedCategoryId: 'cat_alimentacion',
      confidence: 0.86 + _random.nextDouble() * 0.13,
      status: OcrStatus.success,
      source: source,
      documentReference: source == OcrSource.pdf
          ? 'factura_demo.pdf'
          : 'imagen_demo.jpg',
      documentPath: documentPath,
      documentName: documentName,
    );
  }

  @override
  Future<OcrResultEntity> correctReceipt(
    OcrResultEntity result, {
    required double amount,
    required DateTime date,
    required String merchant,
    required String categoryId,
  }) async => result.copyWith(
    amount: amount,
    date: date,
    merchant: merchant,
    suggestedCategoryId: categoryId,
    status: OcrStatus.success,
    confidence: 1,
    warnings: const [],
  );
}
