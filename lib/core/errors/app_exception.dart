/// Base type for all recoverable errors surfaced to the UI as a clear,
/// human-readable message (see [messageKey] which maps to a localized string).
sealed class AppException implements Exception {
  const AppException(this.messageKey, [this.details]);

  /// Key looked up in [AppLocalizations] to produce a translated message.
  final String messageKey;

  /// Optional technical details, never shown directly to the end user.
  final String? details;

  @override
  String toString() => 'AppException($messageKey${details != null ? ': $details' : ''})';
}

class CameraPermissionDeniedException extends AppException {
  const CameraPermissionDeniedException() : super('errorCameraPermissionDenied');
}

class LocationPermissionDeniedException extends AppException {
  const LocationPermissionDeniedException() : super('errorLocationPermissionDenied');
}

class LocationUnavailableException extends AppException {
  const LocationUnavailableException([String? details]) : super('errorLocationUnavailable', details);
}

class CameraCaptureFailedException extends AppException {
  const CameraCaptureFailedException([String? details]) : super('errorCameraCaptureFailed', details);
}

class OcrFailedException extends AppException {
  const OcrFailedException([String? details]) : super('errorOcrFailed', details);
}

class NoPlateDetectedException extends AppException {
  const NoPlateDetectedException() : super('errorNoPlateDetected');
}

class PhotoSaveFailedException extends AppException {
  const PhotoSaveFailedException([String? details]) : super('errorPhotoSaveFailed', details);
}

class DatabaseUnavailableException extends AppException {
  const DatabaseUnavailableException([String? details]) : super('errorDatabaseUnavailable', details);
}

class ExportFailedException extends AppException {
  const ExportFailedException([String? details]) : super('errorExportFailed', details);
}
