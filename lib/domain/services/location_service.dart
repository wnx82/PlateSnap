/// A single GPS fix: latitude/longitude in decimal degrees and horizontal
/// accuracy in meters, when the platform provides it.
class GpsPosition {
  const GpsPosition({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
}

/// Abstraction over device location permission and the current GPS fix.
///
/// PlateSnap never tracks location continuously: this service is only ever
/// called once, synchronously with a manual capture.
abstract class LocationService {
  Future<bool> hasLocationPermission();

  Future<bool> requestLocationPermission();

  Future<bool> isLocationPermissionPermanentlyDenied();

  /// Whether device location services (GPS) are enabled at all.
  Future<bool> isLocationServiceEnabled();

  /// Returns the current position, or `null` if the permission is denied.
  /// Throws [LocationUnavailableException] if the position could not be
  /// determined (e.g. GPS disabled, timeout).
  Future<GpsPosition?> getCurrentPosition();
}
