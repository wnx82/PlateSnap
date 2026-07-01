import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:platesnap/core/constants/app_constants.dart';
import 'package:platesnap/domain/entities/capture_record.dart';
import 'package:platesnap/domain/repositories/capture_repository.dart';
import 'package:platesnap/features/history/presentation/history_screen.dart';
import 'package:platesnap/presentation/providers/repository_providers.dart';

import '../test_helpers/mocks.dart';
import '../test_helpers/pump_app.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const CaptureQuery());
  });

  late MockCaptureRepository repository;

  CaptureRecord buildRecord({required String id, String plate = '1-ABC-123', PlateCountry country = PlateCountry.be}) {
    final DateTime at = DateTime(2026, 2, 15, 9, 0);
    return CaptureRecord(
      id: id,
      imagePath: '/tmp/does-not-exist-$id.jpg',
      detectedPlate: plate,
      rawOcrText: plate,
      countryCode: country,
      capturedAt: at,
      createdAt: at,
      updatedAt: at,
    );
  }

  setUp(() {
    repository = MockCaptureRepository();
  });

  testWidgets('shows an empty state when there is no capture', (WidgetTester tester) async {
    when(() => repository.watchAll(query: any(named: 'query'))).thenAnswer((_) => Stream<List<CaptureRecord>>.value(<CaptureRecord>[]));

    await pumpApp(
      tester,
      const HistoryScreen(),
      overrides: <Override>[captureRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pump();

    expect(find.text('Aucune capture enregistrée'), findsOneWidget);
  });

  testWidgets('lists captures with their plate and country badge', (WidgetTester tester) async {
    when(() => repository.watchAll(query: any(named: 'query'))).thenAnswer(
      (_) => Stream<List<CaptureRecord>>.value(<CaptureRecord>[
        buildRecord(id: '1', plate: '1-ABC-123', country: PlateCountry.be),
        buildRecord(id: '2', plate: 'AB-123-CD', country: PlateCountry.fr),
      ]),
    );

    await pumpApp(
      tester,
      const HistoryScreen(),
      overrides: <Override>[captureRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pump();

    expect(find.text('1-ABC-123'), findsOneWidget);
    expect(find.text('AB-123-CD'), findsOneWidget);
    expect(find.text('BE'), findsOneWidget);
    expect(find.text('FR'), findsOneWidget);
  });

  testWidgets('typing in the search field re-queries the repository', (WidgetTester tester) async {
    when(() => repository.watchAll(query: any(named: 'query'))).thenAnswer((_) => Stream<List<CaptureRecord>>.value(<CaptureRecord>[]));

    await pumpApp(
      tester,
      const HistoryScreen(),
      overrides: <Override>[captureRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'ABC');
    await tester.pump();

    final List<dynamic> captured = verify(() => repository.watchAll(query: captureAny(named: 'query'))).captured;
    final CaptureQuery lastQuery = captured.last as CaptureQuery;
    expect(lastQuery.searchText, 'ABC');
  });
}
