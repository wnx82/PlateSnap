/// Privacy-related settings and photo-anonymization helpers.
///
/// Centralizes every decision that affects what leaves the app (exports) and
/// what the user has been told about data handling, so no other service has
/// to duplicate that logic.
abstract class PrivacyService {
  Future<bool> hasSeenPrivacyIntro();

  Future<void> setHasSeenPrivacyIntro(bool value);

  Future<bool> isBlurPlateOnExportEnabled();

  Future<void> setBlurPlateOnExport(bool value);

  Future<bool> isKeepOriginalPhotoEnabled();

  Future<void> setKeepOriginalPhoto(bool value);

  /// Produces a copy of the image at [imagePath] with the plate region
  /// blurred out, using [plateBoundingBox] when known (falls back to
  /// blurring the lower-center area of the photo otherwise). Returns the
  /// path of the newly created, blurred file; the original is left untouched.
  Future<String> blurPlateRegion(String imagePath, {PlateBoundingBox? plateBoundingBox});

  /// Permanently deletes every capture, photo and thumbnail.
  Future<void> deleteAllData();
}

/// Normalized (0..1) bounding box of a detected plate within its source
/// image, as reported by the OCR text block.
class PlateBoundingBox {
  const PlateBoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;
}
