import '../services/location_service.dart';
import '../services/plate_recognition_service.dart';

/// Transient, in-memory state of a capture between the moment the photo is
/// taken and the moment the user confirms it on the validation screen.
class DraftCapture {
  const DraftCapture({
    required this.imagePath,
    required this.capturedAt,
    this.gpsPosition,
    this.locationPermissionDenied = false,
    this.locationError,
    this.recognition,
    this.recognitionFailed = false,
    this.correctedPlate,
  });

  final String imagePath;
  final DateTime capturedAt;
  final GpsPosition? gpsPosition;

  /// True when the user explicitly denied the location permission, so the
  /// UI can show a specific, non-alarming notice instead of a generic error.
  final bool locationPermissionDenied;

  /// Set when the GPS position could not be determined for a reason other
  /// than a permission denial (service disabled, timeout...).
  final String? locationError;

  /// Result of [PlateRecognitionService.recognize], once it has run.
  final PlateRecognitionResult? recognition;

  /// True when plate recognition threw (OCR failure) rather than simply
  /// finding no matching format.
  final bool recognitionFailed;

  /// Plate text after manual user correction on the validation screen.
  final String? correctedPlate;

  /// Whether there is already a plate value worth showing read-only
  /// (auto-detected), as opposed to needing an editable field right away.
  bool get hasUsablePlate => recognition != null && recognition!.hasDetectedPlate;

  DraftCapture copyWith({
    PlateRecognitionResult? recognition,
    bool? recognitionFailed,
    String? correctedPlate,
  }) {
    return DraftCapture(
      imagePath: imagePath,
      capturedAt: capturedAt,
      gpsPosition: gpsPosition,
      locationPermissionDenied: locationPermissionDenied,
      locationError: locationError,
      recognition: recognition ?? this.recognition,
      recognitionFailed: recognitionFailed ?? this.recognitionFailed,
      correctedPlate: correctedPlate ?? this.correctedPlate,
    );
  }
}
