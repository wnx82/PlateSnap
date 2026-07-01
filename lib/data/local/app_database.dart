import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/capture_records_table.dart';

part 'app_database.g.dart';

/// PlateSnap's single local SQLite database. Everything lives in the app's
/// private document directory; there is no remote/cloud connection.
@DriftDatabase(tables: <Type>[CaptureRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.withExecutor(super.executor);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, 'platesnap.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
