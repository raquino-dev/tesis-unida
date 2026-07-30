import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/ocr/domain/ocr_repository.dart';

class PickedDocument {
  final OcrSource source;
  final String path;
  final String name;
  final int size;

  const PickedDocument({
    required this.source,
    required this.path,
    required this.name,
    required this.size,
  });
}

class AttachmentPickerService {
  AttachmentPickerService._();

  static final _imagePicker = ImagePicker();
  static const maxSizeBytes = 10 * 1024 * 1024;

  static Future<PickedDocument?> pick(OcrSource source) async {
    switch (source) {
      case OcrSource.camera:
      case OcrSource.gallery:
        final image = await _imagePicker.pickImage(
          source: source == OcrSource.camera
              ? ImageSource.camera
              : ImageSource.gallery,
          imageQuality: 88,
          maxWidth: 2400,
        );
        if (image == null) return null;
        return _fromPath(source, image.path, image.name);
      case OcrSource.pdf:
      case OcrSource.xml:
        final extension = source == OcrSource.pdf ? 'pdf' : 'xml';
        final file = await openFile(
          acceptedTypeGroups: [
            XTypeGroup(
              label: source == OcrSource.pdf
                  ? 'Documentos PDF'
                  : 'Comprobantes XML',
              extensions: [extension],
            ),
          ],
        );
        if (file == null) return null;
        return _fromPath(source, file.path, file.name);
    }
  }

  static Future<PickedDocument> _fromPath(
    OcrSource source,
    String path,
    String name,
  ) async {
    final file = File(path);
    final size = await file.length();
    if (size <= 0) {
      throw const FormatException('El archivo seleccionado está vacío.');
    }
    if (size > maxSizeBytes) {
      throw const FormatException('El archivo supera el límite de 10 MB.');
    }
    return PickedDocument(source: source, path: path, name: name, size: size);
  }
}
