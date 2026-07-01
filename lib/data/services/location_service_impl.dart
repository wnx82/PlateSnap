import 'package:geolocator/geolocator.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/services/location_service.dart';

/// [LocationService] implementation backed by `geolocator`.
///
/// Only ever queries the current position on demand (see
/// [getCurrentPosition]); PlateSnap never subscribes to a continuous
/// position stream, matching the "no background tracking" requirement.
class LocationServiceImpl implements LocationService {
  @override
  Future<bool> hasLocationPermission() async {
    final LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> isLocationPermissionPermanentlyDenied() async {
    final LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.deniedForever;
  }

  @override
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<GpsPosition?> getCurrentPosition() async {
    final bool hasPermission = await hasLocationPermission();
    if (!hasPermission) {
      return null;
    }
    final bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationUnavailableException('Location services are disabled');
    }
    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return GpsPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMeters: position.accuracy,
      );
    } on Exception catch (e) {
      throw LocationUnavailableException(e.toString());
    }
  }
}
