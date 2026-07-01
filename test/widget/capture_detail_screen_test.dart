import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:platesnap/core/constants/app_constants.dart';
import 'package:platesnap/domain/entities/capture_record.dart';
import 'package:platesnap/features/capture_detail/presentation/capture_detail_screen.dart';
import 'package:platesnap/presentation/providers/repository_providers.dart';

import '../test_helpers/mocks.dart';
import '../test_helpers/pump_app.dart';

void main() {
  late MockCaptureRepository repository;

  final CaptureRecord record = CaptureRecord(
    id: 'capture-1',
    imagePath: '/tmp/does-not-exist.jpg',
    detectedPlate: '1-ABC-123',
    rawOcrText: '1-ABC-123',
    countryCode: PlateCountry.be,
    confidence: 0.9,
    latitude: 50.85,
    longitude: 4.35,
    gpsAccuracy: 10,
    capturedAt: DateTime(2026, 2, 20, 8, 15),
    createdAt: DateTime(2026, 2, 20, 8, 15),
    updatedAt: DateTime(2026, 2, 20, 8, 15),
  );

  setUp(() {
    repository = MockCaptureRepository();
    when(() => repository.getById('capture-1')).thenAnswer((_) async => record);
  });

  testWidgets('shows the plate, country and GPS coordinates of the capture', (WidgetTester tester) async {
    await pumpApp(
      tester,
      const CaptureDetailScreen(captureId: 'capture-1'),
      overrides: <Override>[captureRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('1-ABC-123'), findsOneWidget);
    expect(find.text('BE'), findsOneWidget);
    expect(find.textContaining('50.850000'), findsOneWidget);
  });

  testWidgets('tapping delete shows a confirmation dialog before deleting anything', (WidgetTester tester) async {
    await pumpApp(
      tester,
      const CaptureDetailScreen(captureId: 'capture-1'),
      overrides: <Override>[captureRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();

    expect(find.text('Supprimer cette capture ?'), findsOneWidget);
    verifyNever(() => repository.delete(any()));
  });

  testWidgets('tapping "Modifier" reveals an editable plate field', (WidgetTester tester) async {
    await pumpApp(
      tester,
      const CaptureDetailScreen(captureId: 'capture-1'),
      overrides: <Override>[captureRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pump();
    await tester.pump();

    expect(find.widgetWithText(TextField, '1-ABC-123'), findsNothing);

    await tester.tap(find.text('Modifier'));
    await tester.pump();

    expect(find.widgetWithText(TextField, '1-ABC-123'), findsOneWidget);
  });
}
