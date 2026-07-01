import '../services/location_service.dart';
import '../services/plate_recognition_service.dart';

/// Transient, in-memory state of a capture between the moment the photo is
/// taken and the moment the user confirms it on the validation screen.
///
/// [recognition] is `null` until plate recognition has run (wired in a
/// later branch); the validation screen adapts its UI accordingly.
class DraftCapture {
  const DraftCapture({
    required this.imagePath,
    required this.capturedAt,
    this.gpsPosition,
    this.locationPermissionDenied = false,
    this.locationError,
    this.recognition,
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

  final PlateRecognitionResult? recognition;

  /// Plate text after manual user correction on the validation screen.
  final String? correctedPlate;

  DraftCapture copyWith({
    PlateRecognitionResult? recognition,
    String? correctedPlate,
  }) {
    return DraftCapture(
      imagePath: imagePath,
      capturedAt: capturedAt,
      gpsPosition: gpsPosition,
      locationPermissionDenied: locationPermissionDenied,
      locationError: locationError,
      recognition: recognition ?? this.recognition,
      correctedPlate: correctedPlate ?? this.correctedPlate,
    );
  }
}
