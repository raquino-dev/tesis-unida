import 'ocr_result_entity.dart';

enum OcrSource { camera, gallery, pdf, xml }

abstract class OcrRepository {
  Future<OcrResultEntity> processReceipt(
    OcrSource source, {
    String? documentPath,
    String? documentName,
  });
}
