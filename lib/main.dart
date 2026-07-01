import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/history/presentation/history_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/onboarding/presentation/privacy_onboarding_screen.dart';
import 'features/privacy/presentation/privacy_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'presentation/providers/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool hasSeenPrivacyIntro = prefs.getBool(AppConstants.prefHasSeenPrivacyIntro) ?? false;

  runApp(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        hasSeenPrivacyIntroProvider.overrideWith((Ref ref) => hasSeenPrivacyIntro),
      ],
      child: const PlateSnapApp(),
    ),
  );
}

/// Root widget wiring theme, localization and routing for PlateSnap.
class PlateSnapApp extends ConsumerWidget {
  const PlateSnapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final Locale? locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'PlateSnap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const _AppEntryPoint(),
      routes: <String, WidgetBuilder>{
        '/history': (_) => const HistoryScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/privacy': (_) => const PrivacyScreen(),
      },
    );
  }
}

/// Shows the first-launch privacy notice before anything else, then the
/// home screen from then on.
class _AppEntryPoint extends ConsumerWidget {
  const _AppEntryPoint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasSeenPrivacyIntro = ref.watch(hasSeenPrivacyIntroProvider);
    return hasSeenPrivacyIntro ? const HomeScreen() : const PrivacyOnboardingScreen();
  }
}
