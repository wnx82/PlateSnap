import '../errors/app_exception.dart';
import '../l10n/generated/app_localizations.dart';

/// Maps an [AppException] to the clear, localized message it should show
/// the user (see the "Gestion des erreurs" requirement: every failure must
/// surface understandable feedback, never a raw stack trace).
String appExceptionMessage(AppLocalizations l10n, AppException error) {
  return switch (error) {
    CameraPermissionDeniedException() => l10n.errorCameraPermissionDenied,
    LocationPermissionDeniedException() => l10n.errorLocationPermissionDenied,
    LocationUnavailableException() => l10n.errorLocationUnavailable,
    CameraCaptureFailedException() => l10n.errorCameraCaptureFailed,
    OcrFailedException() => l10n.errorOcrFailed,
    NoPlateDetectedException() => l10n.errorNoPlateDetected,
    PhotoSaveFailedException() => l10n.errorPhotoSaveFailed,
    DatabaseUnavailableException() => l10n.errorDatabaseUnavailable,
    ExportFailedException() => l10n.errorExportFailed,
  };
}
