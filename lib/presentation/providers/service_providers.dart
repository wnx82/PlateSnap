import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/camera_service_impl.dart';
import '../../domain/services/camera_service.dart';

/// Singleton [CameraService] instance shared across the app.
final Provider<CameraService> cameraServiceProvider = Provider<CameraService>(
  (Ref ref) => CameraServiceImpl(),
);
