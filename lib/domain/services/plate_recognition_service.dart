import '../../core/constants/app_constants.dart';

/// One possible plate reading, ranked among [PlateRecognitionResult.candidates].
class PlateCandidate {
  const PlateCandidate({
    required this.text,
    required this.countryCode,
    required this.confidence,
  });

  final String text;
  final PlateCountry countryCode;
  final double confidence;
}

/// Outcome of running [PlateRecognitionService.recognize] on a photo.
class PlateRecognitionResult {
  const PlateRecognitionResult({
    required this.rawOcrText,
    required this.detectedPlate,
    required this.countryCode,
    required this.confidence,
    required this.candidates,
  });

  /// Full, unmodified OCR output for the image. Always kept, even when a
  /// plate is confidently identified, so the user can fall back to it.
  final String rawOcrText;

  /// Best-guess cleaned plate text, or an empty string if nothing matched a
  /// known format.
  final String detectedPlate;

  final PlateCountry countryCode;

  /// Confidence in the [0, 1] range for [detectedPlate], or `null` when no
  /// format matched.
  final double? confidence;

  /// Other candidate readings (including lower-confidence or other-country
  /// matches) ordered from most to least likely.
  final List<PlateCandidate> candidates;

  bool get hasDetectedPlate => detectedPlate.isNotEmpty;
}

/// On-device OCR + license-plate format matching.
///
/// Kept intentionally simple and swappable in V1 (OCR + regex cleanup), with
/// an interface stable enough that a dedicated ML detector could later
/// replace or augment the implementation without touching call sites.
abstract class PlateRecognitionService {
  Future<PlateRecognitionResult> recognize(String imagePath);
}
