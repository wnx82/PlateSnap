import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/camera_service_impl.dart';
import '../../data/services/location_service_impl.dart';
import '../../domain/services/camera_service.dart';
import '../../domain/services/location_service.dart';

/// Singleton [CameraService] instance shared across the app.
final Provider<CameraService> cameraServiceProvider = Provider<CameraService>(
  (Ref ref) => CameraServiceImpl(),
);

/// Singleton [LocationService] instance shared across the app.
final Provider<LocationService> locationServiceProvider = Provider<LocationService>(
  (Ref ref) => LocationServiceImpl(),
);
