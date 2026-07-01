import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/errors/app_exception.dart';
import '../../domain/entities/capture_record.dart';
import '../../domain/services/export_service.dart';
import '../../domain/services/privacy_service.dart';

/// [ExportService] implementation. Every export is written to a local
/// temporary file and handed back as a path; nothing is uploaded anywhere.
/// It is entirely up to the caller (a user action) to then share that file
/// via the OS share sheet.
class ExportServiceImpl implements ExportService {
  ExportServiceImpl(this._privacyService);

  final PrivacyService _privacyService;

  static const List<String> _csvHeader = <String>[
    'id',
    'plate',
    'detected_plate',
    'corrected_plate',
    'country',
    'confidence',
    'latitude',
    'longitude',
    'gps_accuracy_m',
    'captured_at',
    'note',
  ];

  @override
  Future<String> exportToCsv(List<CaptureRecord> records) async {
    try {
      final List<List<Object?>> rows = <List<Object?>>[
        _csvHeader,
        for (final CaptureRecord r in records)
          <Object?>[
            r.id,
            r.displayPlate,
            r.detectedPlate,
            r.correctedPlate ?? '',
            r.countryCode.name,
            r.confidence,
            r.latitude,
            r.longitude,
            r.gpsAccuracy,
            r.capturedAt.toIso8601String(),
            r.note ?? '',
          ],
      ];
      final String csvContent = const ListToCsvConverter().convert(rows);
      final File file = await _exportFile('platesnap_export', 'csv');
      await file.writeAsString(csvContent);
      return file.path;
    } on Exception catch (e) {
      throw ExportFailedException(e.toString());
    }
  }

  @override
  Future<String> exportToJson(List<CaptureRecord> records) async {
    try {
      final List<Map<String, Object?>> data = records.map(_toJsonMap).toList();
      final File file = await _exportFile('platesnap_export', 'json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
      return file.path;
    } on Exception catch (e) {
      throw ExportFailedException(e.toString());
    }
  }

  @override
  Future<ExportedCapture> exportSingle(CaptureRecord record, {required bool blurPlate}) async {
    try {
      final String photoPath = blurPlate ? await _privacyService.blurPlateRegion(record.imagePath) : record.imagePath;
      final Map<String, Object?> data = <String, Object?>{
        ..._toJsonMap(record),
        'photoFile': p.basename(photoPath),
      };
      final File jsonFile = await _exportFile('platesnap_capture_${record.id}', 'json');
      await jsonFile.writeAsString(const JsonEncoder.withIndent('  ').convert(data));

      // Copy the (possibly blurred) photo alongside the JSON so both can be
      // shared together from the same export directory.
      final File photoCopy = File(p.join(p.dirname(jsonFile.path), p.basename(photoPath)));
      if (photoPath != photoCopy.path) {
        await File(photoPath).copy(photoCopy.path);
      }
      return ExportedCapture(jsonPath: jsonFile.path, photoPath: photoCopy.path);
    } on AppException {
      rethrow;
    } on Exception catch (e) {
      throw ExportFailedException(e.toString());
    }
  }

  Map<String, Object?> _toJsonMap(CaptureRecord r) => <String, Object?>{
        'id': r.id,
        'plate': r.displayPlate,
        'detectedPlate': r.detectedPlate,
        'correctedPlate': r.correctedPlate,
        'rawOcrText': r.rawOcrText,
        'country': r.countryCode.name,
        'confidence': r.confidence,
        'latitude': r.latitude,
        'longitude': r.longitude,
        'gpsAccuracyMeters': r.gpsAccuracy,
        'capturedAt': r.capturedAt.toIso8601String(),
        'note': r.note,
      };

  Future<File> _exportFile(String baseName, String extension) async {
    final Directory dir = await getTemporaryDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return File(p.join(dir.path, '$baseName-$timestamp.$extension'));
  }
}
