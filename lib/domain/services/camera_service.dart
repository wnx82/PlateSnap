/// Abstraction over camera permission handling and captured-file persistence.
///
/// Live preview/capture itself is driven by a `CameraController` inside the
/// capture screen (the `camera` package ties the controller to widget
/// lifecycle), but every permission check and every write to disk goes
/// through this service so the capture screen has no direct file/permission
/// logic in it.
abstract class CameraService {
  /// Whether the camera permission is currently granted.
  Future<bool> hasCameraPermission();

  /// Requests the camera permission, returning whether it was granted.
  Future<bool> requestCameraPermission();

  /// Whether the permission was permanently denied (user must go to
  /// system settings to change it).
  Future<bool> isCameraPermissionPermanentlyDenied();

  /// Copies a freshly captured photo (typically a temp file from the camera
  /// plugin) into PlateSnap's permanent app storage and returns the new,
  /// stable file path.
  Future<String> persistCapturedImage(String temporaryImagePath);

  /// Generates and persists a small thumbnail for [imagePath], returning its
  /// file path.
  Future<String> generateThumbnail(String imagePath);

  /// Deletes a previously persisted image and its thumbnail, if present.
  Future<void> deleteImage({required String imagePath, String? thumbnailPath});
}
