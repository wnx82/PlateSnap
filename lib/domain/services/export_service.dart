import '../entities/capture_record.dart';

/// Produces user-initiated CSV/JSON exports of captures.
///
/// Exports are never sent anywhere automatically: the resulting file path is
/// handed back to the UI, which then lets the user share/save it explicitly
/// (see the OS share sheet triggered from the settings/detail screens).
abstract class ExportService {
  /// Writes all [records] to a CSV file and returns its path.
  Future<String> exportToCsv(List<CaptureRecord> records);

  /// Writes all [records] to a JSON file and returns its path.
  Future<String> exportToJson(List<CaptureRecord> records);

  /// Exports a single [record] to JSON, optionally producing a blurred copy
  /// of the photo (see [PrivacyService.blurPlateRegion]) referenced from the
  /// export instead of the original image.
  Future<String> exportSingle(CaptureRecord record, {required bool blurPlate});
}
