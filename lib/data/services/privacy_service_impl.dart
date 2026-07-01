import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/capture_record.dart';
import '../../domain/repositories/capture_repository.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/services/privacy_service.dart';

/// [PrivacyService] implementation. Settings are stored locally via
/// `shared_preferences`; blurring is done fully on-device with the `image`
/// package; "delete everything" removes both the database rows and every
/// photo/thumbnail file so nothing is left behind.
class PrivacyServiceImpl implements PrivacyService {
  PrivacyServiceImpl(this._prefs, this._repository, this._cameraService);

  final SharedPreferences _prefs;
  final CaptureRepository _repository;
  final CameraService _cameraService;

  @override
  Future<bool> hasSeenPrivacyIntro() async => _prefs.getBool(AppConstants.prefHasSeenPrivacyIntro) ?? false;

  @override
  Future<void> setHasSeenPrivacyIntro(bool value) async {
    await _prefs.setBool(AppConstants.prefHasSeenPrivacyIntro, value);
  }

  @override
  Future<bool> isBlurPlateOnExportEnabled() async => _prefs.getBool(AppConstants.prefBlurPlateOnExport) ?? false;

  @override
  Future<void> setBlurPlateOnExport(bool value) async {
    await _prefs.setBool(AppConstants.prefBlurPlateOnExport, value);
  }

  @override
  Future<bool> isKeepOriginalPhotoEnabled() async => _prefs.getBool(AppConstants.prefKeepOriginalPhoto) ?? true;

  @override
  Future<void> setKeepOriginalPhoto(bool value) async {
    await _prefs.setBool(AppConstants.prefKeepOriginalPhoto, value);
  }

  @override
  Future<String> blurPlateRegion(String imagePath, {PlateBoundingBox? plateBoundingBox}) async {
    try {
      final Uint8List bytes = await File(imagePath).readAsBytes();
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw ExportFailedException('Unable to decode image: $imagePath');
      }

      final _PixelRect rect = _resolveRect(decoded.width, decoded.height, plateBoundingBox);
      final img.Image region = img.copyCrop(decoded, x: rect.x, y: rect.y, width: rect.width, height: rect.height);
      final img.Image blurredRegion = img.gaussianBlur(region, radius: 20);
      img.compositeImage(decoded, blurredRegion, dstX: rect.x, dstY: rect.y);

      final Directory outDir = await getTemporaryDirectory();
      final String outPath = p.join(outDir.path, 'blurred_${p.basename(imagePath)}');
      await File(outPath).writeAsBytes(img.encodeJpg(decoded, quality: 85));
      return outPath;
    } on ExportFailedException {
      rethrow;
    } on Exception catch (e) {
      throw ExportFailedException(e.toString());
    }
  }

  /// Converts a normalized [plateBoundingBox] to pixel coordinates, or falls
  /// back to the lower-center area of the photo (where a plate typically
  /// ends up when the vehicle rear/front fills the frame) when the exact
  /// region isn't known.
  _PixelRect _resolveRect(int width, int height, PlateBoundingBox? plateBoundingBox) {
    if (plateBoundingBox != null) {
      final int x = (plateBoundingBox.left * width).round().clamp(0, width - 1);
      final int y = (plateBoundingBox.top * height).round().clamp(0, height - 1);
      final int w = ((plateBoundingBox.right - plateBoundingBox.left) * width).round().clamp(1, width - x);
      final int h = ((plateBoundingBox.bottom - plateBoundingBox.top) * height).round().clamp(1, height - y);
      return _PixelRect(x, y, w, h);
    }
    final int x = (width * 0.10).round();
    final int y = (height * 0.55).round();
    final int w = (width * 0.80).round();
    final int h = (height * 0.30).round();
    return _PixelRect(x, y, w, h);
  }

  @override
  Future<void> deleteAllData() async {
    try {
      final List<CaptureRecord> records = await _repository.getAll();
      for (final CaptureRecord record in records) {
        await _cameraService.deleteImage(imagePath: record.imagePath, thumbnailPath: record.thumbnailPath);
      }
      await _repository.deleteAll();
    } on AppException {
      rethrow;
    } on Exception catch (e) {
      throw DatabaseUnavailableException(e.toString());
    }
  }
}

class _PixelRect {
  const _PixelRect(this.x, this.y, this.width, this.height);

  final int x;
  final int y;
  final int width;
  final int height;
}
