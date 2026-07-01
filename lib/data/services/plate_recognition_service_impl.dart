import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/services/plate_recognition_service.dart';
import 'plate/plate_recognition_engine.dart';

/// [PlateRecognitionService] implementation: on-device OCR (ML Kit Text
/// Recognition, no network call) followed by the pure [PlateRecognitionEngine]
/// for format matching and OCR-confusion cleanup.
class PlateRecognitionServiceImpl implements PlateRecognitionService {
  PlateRecognitionServiceImpl({TextRecognizer? textRecognizer, PlateRecognitionEngine? engine})
      : _textRecognizer = textRecognizer ?? TextRecognizer(script: TextRecognitionScript.latin),
        _engine = engine ?? const PlateRecognitionEngine();

  final TextRecognizer _textRecognizer;
  final PlateRecognitionEngine _engine;

  @override
  Future<PlateRecognitionResult> recognize(String imagePath) async {
    final String rawOcrText;
    try {
      final InputImage inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognized = await _textRecognizer.processImage(inputImage);
      rawOcrText = recognized.text;
    } on Exception catch (e) {
      throw OcrFailedException(e.toString());
    }

    // When nothing matches a known format, analyzeText still returns a
    // result (unknown country, empty detectedPlate, raw OCR text kept) so
    // the validation screen can offer manual entry instead of failing hard.
    return _engine.analyzeText(rawOcrText);
  }

  /// Releases the underlying ML Kit recognizer. Call when the app/service
  /// scope providing this instance is disposed.
  Future<void> dispose() => _textRecognizer.close();
}
