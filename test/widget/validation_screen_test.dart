import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platesnap/core/constants/app_constants.dart';
import 'package:platesnap/domain/entities/draft_capture.dart';
import 'package:platesnap/domain/services/location_service.dart';
import 'package:platesnap/domain/services/plate_recognition_service.dart';
import 'package:platesnap/features/validation/presentation/validation_screen.dart';

import '../test_helpers/pump_app.dart';

void main() {
  // Deliberately a non-existent path: Image.file fails fast on a missing
  // file (no decode attempted), which is what the widget test needs — the
  // photo's pixel content is irrelevant to these tests.
  const String imagePath = '/tmp/platesnap_test_does_not_exist.jpg';

  DraftCapture buildDraft({PlateRecognitionResult? recognition}) {
    return DraftCapture(
      imagePath: imagePath,
      capturedAt: DateTime(2026, 3, 1, 14, 30),
      gpsPosition: const GpsPosition(latitude: 50.85, longitude: 4.35, accuracyMeters: 8),
      recognition: recognition,
    );
  }

  testWidgets('shows the detected plate, its country badge and GPS info', (WidgetTester tester) async {
    final DraftCapture draft = buildDraft(
      recognition: const PlateRecognitionResult(
        rawOcrText: '1-ABC-123',
        detectedPlate: '1-ABC-123',
        countryCode: PlateCountry.be,
        confidence: 0.95,
        candidates: <PlateCandidate>[
          PlateCandidate(text: '1-ABC-123', countryCode: PlateCountry.be, confidence: 0.95),
        ],
      ),
    );

    await pumpApp(
      tester,
      ValidationScreen(
        draft: draft,
        onSave: (BuildContext context, String plate) async {},
        onRetake: () {},
        onCancel: () {},
      ),
    );
    await tester.pump();

    expect(find.text('1-ABC-123'), findsOneWidget);
    expect(find.text('BE'), findsOneWidget);
  });

  testWidgets('offers manual entry when no plate was detected', (WidgetTester tester) async {
    final DraftCapture draft = buildDraft(
      recognition: const PlateRecognitionResult(
        rawOcrText: 'GARBLED TEXT',
        detectedPlate: '',
        countryCode: PlateCountry.unknown,
        confidence: null,
        candidates: <PlateCandidate>[],
      ),
    );

    await pumpApp(
      tester,
      ValidationScreen(
        draft: draft,
        onSave: (BuildContext context, String plate) async {},
        onRetake: () {},
        onCancel: () {},
      ),
    );
    await tester.pump();

    expect(find.text('Aucune plaque détectée automatiquement. Vous pouvez la saisir manuellement.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('tapping "Enregistrer" reports the (manually corrected) plate text', (WidgetTester tester) async {
    final DraftCapture draft = buildDraft(
      recognition: const PlateRecognitionResult(
        rawOcrText: '1-ABC-123',
        detectedPlate: '1-ABC-123',
        countryCode: PlateCountry.be,
        confidence: 0.95,
        candidates: <PlateCandidate>[
          PlateCandidate(text: '1-ABC-123', countryCode: PlateCountry.be, confidence: 0.95),
        ],
      ),
    );

    String? savedPlate;
    await pumpApp(
      tester,
      ValidationScreen(
        draft: draft,
        onSave: (BuildContext context, String plate) async => savedPlate = plate,
        onRetake: () {},
        onCancel: () {},
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Enregistrer'));
    await tester.pump();

    expect(savedPlate, '1-ABC-123');
  });
}
