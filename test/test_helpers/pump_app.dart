import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platesnap/core/l10n/generated/app_localizations.dart';

/// Pumps [child] wrapped in a [ProviderScope] (with the given [overrides])
/// and a [MaterialApp] configured with PlateSnap's localization delegates,
/// forced to French so widget tests have deterministic text to match on.
///
/// Uses a tall, phone-sized test surface rather than the default 800x600:
/// several screens (validation, detail) show a photo in a scrollable list
/// and easily overflow the default surface, which makes Flutter's finders
/// (which skip offstage/out-of-viewport content by default) miss content
/// that is actually there.
Future<void> pumpApp(WidgetTester tester, Widget child, {List<Override> overrides = const <Override>[]}) async {
  final Size originalSize = tester.view.physicalSize;
  final double originalDevicePixelRatio = tester.view.devicePixelRatio;
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.physicalSize = originalSize;
    tester.view.devicePixelRatio = originalDevicePixelRatio;
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: child,
      ),
    ),
  );
}
