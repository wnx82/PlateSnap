import '../../core/constants/app_constants.dart';

/// Immutable domain entity representing a single license plate capture.
///
/// This is the single source of truth for a capture across the whole app;
/// the data layer maps it to/from the local SQLite row.
class CaptureRecord {
  const CaptureRecord({
    required this.id,
    required this.imagePath,
    required this.detectedPlate,
    required this.rawOcrText,
    required this.countryCode,
    required this.capturedAt,
    required this.createdAt,
    required this.updatedAt,
    this.thumbnailPath,
    this.correctedPlate,
    this.confidence,
    this.latitude,
    this.longitude,
    this.gpsAccuracy,
    this.note,
    this.isExported = false,
    this.metadataJson,
  });

  final String id;
  final String imagePath;
  final String? thumbnailPath;

  /// Plate text as returned by [PlateRecognitionService], never mutated.
  final String detectedPlate;

  /// Plate text after manual user correction, if any.
  final String? correctedPlate;

  /// Full unprocessed OCR output, kept for troubleshooting/manual correction.
  final String rawOcrText;

  final PlateCountry countryCode;

  /// OCR/format-match confidence in the [0, 1] range, when available.
  final double? confidence;

  final double? latitude;
  final double? longitude;
  final double? gpsAccuracy;

  /// Local device date/time at which the photo was taken.
  final DateTime capturedAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  final String? note;
  final bool isExported;

  /// Free-form JSON-encoded metadata reserved for future extensions
  /// (e.g. ML model version, OCR engine details) without a schema migration.
  final String? metadataJson;

  /// The plate value to display: the user correction if present, otherwise
  /// the automatically detected plate.
  String get displayPlate => (correctedPlate != null && correctedPlate!.trim().isNotEmpty)
      ? correctedPlate!
      : detectedPlate;

  bool get wasManuallyCorrected =>
      correctedPlate != null && correctedPlate!.trim().isNotEmpty && correctedPlate != detectedPlate;

  bool get hasLocation => latitude != null && longitude != null;

  CaptureRecord copyWith({
    String? id,
    String? imagePath,
    String? thumbnailPath,
    String? detectedPlate,
    String? correctedPlate,
    bool clearCorrectedPlate = false,
    String? rawOcrText,
    PlateCountry? countryCode,
    double? confidence,
    double? latitude,
    double? longitude,
    double? gpsAccuracy,
    DateTime? capturedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? note,
    bool clearNote = false,
    bool? isExported,
    String? metadataJson,
  }) {
    return CaptureRecord(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      detectedPlate: detectedPlate ?? this.detectedPlate,
      correctedPlate: clearCorrectedPlate ? null : (correctedPlate ?? this.correctedPlate),
      rawOcrText: rawOcrText ?? this.rawOcrText,
      countryCode: countryCode ?? this.countryCode,
      confidence: confidence ?? this.confidence,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      capturedAt: capturedAt ?? this.capturedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: clearNote ? null : (note ?? this.note),
      isExported: isExported ?? this.isExported,
      metadataJson: metadataJson ?? this.metadataJson,
    );
  }

  @override
  bool operator ==(Object other) => other is CaptureRecord && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
