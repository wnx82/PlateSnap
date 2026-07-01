import '../../core/constants/app_constants.dart';
import '../entities/capture_record.dart';

/// Optional filters applied when listing/watching captures in the history
/// screen.
class CaptureQuery {
  const CaptureQuery({
    this.searchText,
    this.country,
    this.fromDate,
    this.toDate,
  });

  /// Case-insensitive substring match against the effective plate
  /// ([CaptureRecord.displayPlate]).
  final String? searchText;

  final PlateCountry? country;
  final DateTime? fromDate;
  final DateTime? toDate;

  bool get isEmpty => searchText == null && country == null && fromDate == null && toDate == null;
}

/// Aggregate numbers shown on the home screen summary card.
class CaptureStats {
  const CaptureStats({
    required this.totalCaptures,
    required this.lastCaptureAt,
    required this.averageConfidence,
  });

  final int totalCaptures;
  final DateTime? lastCaptureAt;

  /// Average OCR confidence across captures that have one, or `null` when
  /// no capture has a confidence score.
  final double? averageConfidence;
}

/// Persistence boundary for [CaptureRecord]s. The presentation layer only
/// ever talks to this interface, never to the database directly.
abstract class CaptureRepository {
  Future<CaptureRecord> create(CaptureRecord record);

  Future<CaptureRecord?> getById(String id);

  /// Captures ordered most-recent-first, optionally filtered by [query].
  Stream<List<CaptureRecord>> watchAll({CaptureQuery query = const CaptureQuery()});

  Future<List<CaptureRecord>> getAll({CaptureQuery query = const CaptureQuery()});

  Future<void> update(CaptureRecord record);

  Future<void> delete(String id);

  Future<void> deleteAll();

  Stream<CaptureStats> watchStats();
}
