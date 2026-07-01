import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/repositories/capture_repository_impl.dart';
import '../../domain/repositories/capture_repository.dart';

/// Singleton local database, closed when the provider is disposed (i.e.
/// never in practice, since it lives for the app's lifetime).
final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>((Ref ref) {
  final AppDatabase db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final Provider<CaptureRepository> captureRepositoryProvider = Provider<CaptureRepository>(
  (Ref ref) => CaptureRepositoryImpl(ref.watch(appDatabaseProvider)),
);

/// Live summary numbers shown on the home screen.
final StreamProvider<CaptureStats> captureStatsProvider = StreamProvider<CaptureStats>(
  (Ref ref) => ref.watch(captureRepositoryProvider).watchStats(),
);
