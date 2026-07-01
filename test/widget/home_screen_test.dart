import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:platesnap/domain/repositories/capture_repository.dart';
import 'package:platesnap/features/home/presentation/home_screen.dart';
import 'package:platesnap/presentation/providers/repository_providers.dart';

import '../test_helpers/mocks.dart';
import '../test_helpers/pump_app.dart';

void main() {
  late MockCaptureRepository repository;

  setUp(() {
    repository = MockCaptureRepository();
  });

  testWidgets('shows the app name and the three main actions', (WidgetTester tester) async {
    when(() => repository.watchStats()).thenAnswer(
      (_) => Stream<CaptureStats>.value(const CaptureStats(totalCaptures: 0, lastCaptureAt: null, averageConfidence: null)),
    );

    await pumpApp(
      tester,
      const HomeScreen(),
      overrides: <Override>[captureRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pump();

    expect(find.text('PlateSnap'), findsWidgets);
    expect(find.text('Nouvelle capture'), findsOneWidget);
    expect(find.text('Historique'), findsOneWidget);
    expect(find.text('Paramètres'), findsOneWidget);
  });

  testWidgets('shows the empty-history message when there are no captures yet', (WidgetTester tester) async {
    when(() => repository.watchStats()).thenAnswer(
      (_) => Stream<CaptureStats>.value(const CaptureStats(totalCaptures: 0, lastCaptureAt: null, averageConfidence: null)),
    );

    await pumpApp(
      tester,
      const HomeScreen(),
      overrides: <Override>[captureRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pump();

    expect(find.text('Aucune capture pour le moment'), findsOneWidget);
  });

  testWidgets('shows the total capture count once stats are loaded', (WidgetTester tester) async {
    final DateTime lastCapture = DateTime(2026, 3, 1, 10, 30);
    when(() => repository.watchStats()).thenAnswer(
      (_) => Stream<CaptureStats>.value(
        CaptureStats(totalCaptures: 3, lastCaptureAt: lastCapture, averageConfidence: 0.9),
      ),
    );

    await pumpApp(
      tester,
      const HomeScreen(),
      overrides: <Override>[captureRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pump();

    expect(find.textContaining('3'), findsWidgets);
  });
}
