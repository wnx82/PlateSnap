import 'package:drift/drift.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../domain/entities/capture_record.dart';
import '../../domain/repositories/capture_repository.dart';
import '../local/app_database.dart';

/// [CaptureRepository] implementation backed by the local SQLite database
/// (drift). All reads/writes stay on-device; nothing here ever calls the
/// network.
class CaptureRepositoryImpl implements CaptureRepository {
  CaptureRepositoryImpl(this._db);

  final AppDatabase _db;

  @override
  Future<CaptureRecord> create(CaptureRecord record) async {
    try {
      await _db.into(_db.captureRecords).insert(_toCompanion(record));
      return record;
    } catch (e) {
      throw DatabaseUnavailableException(e.toString());
    }
  }

  @override
  Future<CaptureRecord?> getById(String id) async {
    try {
      final CaptureRecordRow? row = await (_db.select(_db.captureRecords)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      return row == null ? null : _toEntity(row);
    } catch (e) {
      throw DatabaseUnavailableException(e.toString());
    }
  }

  @override
  Stream<List<CaptureRecord>> watchAll({CaptureQuery query = const CaptureQuery()}) {
    final SimpleSelectStatement<$CaptureRecordsTable, CaptureRecordRow> statement = _select(query);
    return statement.watch().map((List<CaptureRecordRow> rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<List<CaptureRecord>> getAll({CaptureQuery query = const CaptureQuery()}) async {
    try {
      final List<CaptureRecordRow> rows = await _select(query).get();
      return rows.map(_toEntity).toList();
    } catch (e) {
      throw DatabaseUnavailableException(e.toString());
    }
  }

  SimpleSelectStatement<$CaptureRecordsTable, CaptureRecordRow> _select(CaptureQuery query) {
    final SimpleSelectStatement<$CaptureRecordsTable, CaptureRecordRow> statement = _db.select(_db.captureRecords);
    if (query.country != null) {
      statement.where((t) => t.countryCode.equals(_countryToDb(query.country!)));
    }
    if (query.searchText != null && query.searchText!.trim().isNotEmpty) {
      final String needle = '%${query.searchText!.trim().toUpperCase()}%';
      statement.where(
        (t) => t.correctedPlate.upper().like(needle) | t.detectedPlate.upper().like(needle),
      );
    }
    if (query.fromDate != null) {
      statement.where((t) => t.capturedAt.isBiggerOrEqualValue(query.fromDate!));
    }
    if (query.toDate != null) {
      statement.where((t) => t.capturedAt.isSmallerOrEqualValue(query.toDate!));
    }
    statement.orderBy(<OrderClauseGenerator<$CaptureRecordsTable>>[
      (t) => OrderingTerm(expression: t.capturedAt, mode: OrderingMode.desc),
    ]);
    return statement;
  }

  @override
  Future<void> update(CaptureRecord record) async {
    try {
      await _db.update(_db.captureRecords).replace(_toCompanion(record));
    } catch (e) {
      throw DatabaseUnavailableException(e.toString());
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await (_db.delete(_db.captureRecords)..where((t) => t.id.equals(id))).go();
    } catch (e) {
      throw DatabaseUnavailableException(e.toString());
    }
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _db.delete(_db.captureRecords).go();
    } catch (e) {
      throw DatabaseUnavailableException(e.toString());
    }
  }

  @override
  Stream<CaptureStats> watchStats() {
    return _db.select(_db.captureRecords).watch().map((List<CaptureRecordRow> rows) {
      if (rows.isEmpty) {
        return const CaptureStats(totalCaptures: 0, lastCaptureAt: null, averageConfidence: null);
      }
      final List<CaptureRecordRow> sorted = List<CaptureRecordRow>.of(rows)
        ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
      final List<double> confidences =
          rows.map((r) => r.confidence).whereType<double>().toList(growable: false);
      final double? average =
          confidences.isEmpty ? null : confidences.reduce((a, b) => a + b) / confidences.length;
      return CaptureStats(
        totalCaptures: rows.length,
        lastCaptureAt: sorted.first.capturedAt,
        averageConfidence: average,
      );
    });
  }

  CaptureRecordsCompanion _toCompanion(CaptureRecord r) {
    return CaptureRecordsCompanion.insert(
      id: r.id,
      imagePath: r.imagePath,
      thumbnailPath: Value<String?>(r.thumbnailPath),
      detectedPlate: r.detectedPlate,
      correctedPlate: Value<String?>(r.correctedPlate),
      rawOcrText: r.rawOcrText,
      countryCode: _countryToDb(r.countryCode),
      confidence: Value<double?>(r.confidence),
      latitude: Value<double?>(r.latitude),
      longitude: Value<double?>(r.longitude),
      gpsAccuracy: Value<double?>(r.gpsAccuracy),
      capturedAt: r.capturedAt,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      note: Value<String?>(r.note),
      isExported: Value<bool>(r.isExported),
      metadataJson: Value<String?>(r.metadataJson),
    );
  }

  CaptureRecord _toEntity(CaptureRecordRow row) {
    return CaptureRecord(
      id: row.id,
      imagePath: row.imagePath,
      thumbnailPath: row.thumbnailPath,
      detectedPlate: row.detectedPlate,
      correctedPlate: row.correctedPlate,
      rawOcrText: row.rawOcrText,
      countryCode: _countryFromDb(row.countryCode),
      confidence: row.confidence,
      latitude: row.latitude,
      longitude: row.longitude,
      gpsAccuracy: row.gpsAccuracy,
      capturedAt: row.capturedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      note: row.note,
      isExported: row.isExported,
      metadataJson: row.metadataJson,
    );
  }

  static String _countryToDb(PlateCountry country) => country.name.toUpperCase();

  static PlateCountry _countryFromDb(String value) => PlateCountry.values.firstWhere(
        (PlateCountry c) => c.name.toUpperCase() == value,
        orElse: () => PlateCountry.unknown,
      );
}
