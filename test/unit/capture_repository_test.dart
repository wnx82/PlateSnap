import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platesnap/core/constants/app_constants.dart';
import 'package:platesnap/data/local/app_database.dart';
import 'package:platesnap/data/repositories/capture_repository_impl.dart';
import 'package:platesnap/domain/entities/capture_record.dart';
import 'package:platesnap/domain/repositories/capture_repository.dart';
import 'package:sqlite3/open.dart';

void main() {
  setUpAll(() {
    // `flutter test` runs on the host Dart VM; on Linux desktop it needs an
    // explicit path to the system sqlite3 shared library (see README ->
    // "Commandes de test"). Android/iOS builds bundle their own via
    // sqlite3_flutter_libs and never hit this branch.
    if (Platform.isLinux) {
      open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlite3.so.0'));
    }
  });

  late AppDatabase db;
  late CaptureRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    repository = CaptureRepositoryImpl(db);
  });

  tearDown(() => db.close());

  CaptureRecord buildRecord({
    required String id,
    PlateCountry country = PlateCountry.be,
    String plate = '1-ABC-123',
    DateTime? capturedAt,
  }) {
    final DateTime at = capturedAt ?? DateTime(2026, 1, 1, 10, 0);
    return CaptureRecord(
      id: id,
      imagePath: '/tmp/$id.jpg',
      detectedPlate: plate,
      rawOcrText: plate,
      countryCode: country,
      capturedAt: at,
      createdAt: at,
      updatedAt: at,
    );
  }

  test('create then getById returns the same capture', () async {
    await repository.create(buildRecord(id: 'a'));

    final CaptureRecord? found = await repository.getById('a');

    expect(found, isNotNull);
    expect(found!.id, 'a');
    expect(found.detectedPlate, '1-ABC-123');
    expect(found.countryCode, PlateCountry.be);
  });

  test('getById returns null for an unknown id', () async {
    expect(await repository.getById('missing'), isNull);
  });

  test('delete removes a single capture', () async {
    await repository.create(buildRecord(id: 'a'));
    await repository.create(buildRecord(id: 'b'));

    await repository.delete('a');

    expect(await repository.getById('a'), isNull);
    expect(await repository.getById('b'), isNotNull);
  });

  test('deleteAll clears every capture', () async {
    await repository.create(buildRecord(id: 'a'));
    await repository.create(buildRecord(id: 'b'));

    await repository.deleteAll();

    expect(await repository.getAll(), isEmpty);
  });

  test('getAll filters by country', () async {
    await repository.create(buildRecord(id: 'a', country: PlateCountry.be, plate: '1-ABC-123'));
    await repository.create(buildRecord(id: 'b', country: PlateCountry.fr, plate: 'AB-123-CD'));

    final List<CaptureRecord> beOnly = await repository.getAll(
      query: const CaptureQuery(country: PlateCountry.be),
    );

    expect(beOnly, hasLength(1));
    expect(beOnly.single.id, 'a');
  });

  test('getAll searches by plate text (case-insensitive)', () async {
    await repository.create(buildRecord(id: 'a', plate: '1-ABC-123'));
    await repository.create(buildRecord(id: 'b', country: PlateCountry.fr, plate: 'AB-123-CD'));

    final List<CaptureRecord> results = await repository.getAll(
      query: const CaptureQuery(searchText: 'abc'),
    );

    expect(results, hasLength(1));
    expect(results.single.id, 'a');
  });

  test('getAll orders results most-recent-first', () async {
    await repository.create(buildRecord(id: 'old', capturedAt: DateTime(2025, 1, 1)));
    await repository.create(buildRecord(id: 'new', capturedAt: DateTime(2026, 1, 1)));

    final List<CaptureRecord> results = await repository.getAll();

    expect(results.map((CaptureRecord r) => r.id).toList(), <String>['new', 'old']);
  });

  test('watchStats reflects total count and average confidence', () async {
    await repository.create(buildRecord(id: 'a').copyWith(confidence: 0.8));
    await repository.create(buildRecord(id: 'b').copyWith(confidence: 0.6));

    final CaptureStats stats = await repository.watchStats().first;

    expect(stats.totalCaptures, 2);
    expect(stats.averageConfidence, closeTo(0.7, 0.0001));
  });
}
