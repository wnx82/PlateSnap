import 'package:drift/drift.dart';

/// SQLite schema (via drift) mirroring the [CaptureRecord] domain entity.
///
/// Country code and confidence are stored as plain text/real rather than a
/// custom drift type converter, keeping the mapping to/from the domain enum
/// explicit and easy to unit test in the repository.
///
/// The generated row class is named `CaptureRecordRow` (via
/// [DataClassName]) to avoid colliding with the domain entity
/// `CaptureRecord`.
@DataClassName('CaptureRecordRow')
class CaptureRecords extends Table {
  TextColumn get id => text()();
  TextColumn get imagePath => text()();
  TextColumn get thumbnailPath => text().nullable()();
  TextColumn get detectedPlate => text()();
  TextColumn get correctedPlate => text().nullable()();
  TextColumn get rawOcrText => text()();

  /// One of 'BE', 'FR', 'UNKNOWN'.
  TextColumn get countryCode => text()();

  RealColumn get confidence => real().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  RealColumn get gpsAccuracy => real().nullable()();

  DateTimeColumn get capturedAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  TextColumn get note => text().nullable()();
  BoolColumn get isExported => boolean().withDefault(const Constant(false))();
  TextColumn get metadataJson => text().nullable()();

  @override
  Set<Column> get primaryKey => <Column>{id};
}
