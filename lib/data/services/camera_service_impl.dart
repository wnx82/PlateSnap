import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/services/camera_service.dart';

/// [CameraService] implementation backed by `permission_handler` for
/// permissions and the app's document directory for persistence.
class CameraServiceImpl implements CameraService {
  @override
  Future<bool> hasCameraPermission() async {
    return Permission.camera.status.then((PermissionStatus s) => s.isGranted);
  }

  @override
  Future<bool> requestCameraPermission() async {
    final PermissionStatus status = await Permission.camera.request();
    return status.isGranted;
  }

  @override
  Future<bool> isCameraPermissionPermanentlyDenied() async {
    final PermissionStatus status = await Permission.camera.status;
    return status.isPermanentlyDenied;
  }

  Future<Directory> _capturesDirectory() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory capturesDir = Directory(p.join(appDir.path, AppConstants.capturesDirectoryName));
    if (!await capturesDir.exists()) {
      await capturesDir.create(recursive: true);
    }
    return capturesDir;
  }

  Future<Directory> _thumbnailsDirectory() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory thumbsDir = Directory(p.join(appDir.path, AppConstants.thumbnailsDirectoryName));
    if (!await thumbsDir.exists()) {
      await thumbsDir.create(recursive: true);
    }
    return thumbsDir;
  }

  @override
  Future<String> persistCapturedImage(String temporaryImagePath) async {
    try {
      final Directory dir = await _capturesDirectory();
      final String fileName = '${DateTime.now().microsecondsSinceEpoch}.jpg';
      final String destinationPath = p.join(dir.path, fileName);
      final File source = File(temporaryImagePath);
      await source.copy(destinationPath);
      return destinationPath;
    } on Exception catch (e) {
      throw PhotoSaveFailedException(e.toString());
    }
  }

  @override
  Future<String> generateThumbnail(String imagePath) async {
    try {
      final File source = File(imagePath);
      final Uint8List bytes = await source.readAsBytes();
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw PhotoSaveFailedException('Unable to decode image for thumbnail: $imagePath');
      }
      final img.Image resized = img.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? AppConstants.thumbnailMaxDimension : null,
        height: decoded.height > decoded.width ? AppConstants.thumbnailMaxDimension : null,
      );
      final Directory dir = await _thumbnailsDirectory();
      final String thumbPath = p.join(dir.path, p.basename(imagePath));
      final File thumbFile = File(thumbPath);
      await thumbFile.writeAsBytes(img.encodeJpg(resized, quality: 80));
      return thumbPath;
    } on Exception catch (e) {
      throw PhotoSaveFailedException(e.toString());
    }
  }

  @override
  Future<void> deleteImage({required String imagePath, String? thumbnailPath}) async {
    final File imageFile = File(imagePath);
    if (await imageFile.exists()) {
      await imageFile.delete();
    }
    if (thumbnailPath != null) {
      final File thumbFile = File(thumbnailPath);
      if (await thumbFile.exists()) {
        await thumbFile.delete();
      }
    }
  }
}
