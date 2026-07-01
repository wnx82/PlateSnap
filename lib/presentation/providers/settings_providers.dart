import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../data/services/export_service_impl.dart';
import '../../data/services/privacy_service_impl.dart';
import '../../domain/services/export_service.dart';
import '../../domain/services/privacy_service.dart';
import 'repository_providers.dart';
import 'service_providers.dart';

/// Overridden in `main()` once `SharedPreferences.getInstance()` resolves,
/// so every dependent provider can read settings synchronously.
final Provider<SharedPreferences> sharedPreferencesProvider = Provider<SharedPreferences>(
  (Ref ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden in main()'),
);

/// Whether the user has already seen the first-launch privacy notice.
/// Overridden in `main()` with the persisted value so there is no loading
/// flicker on the very first frame.
final StateProvider<bool> hasSeenPrivacyIntroProvider = StateProvider<bool>((Ref ref) => false);

class BoolPrefNotifier extends StateNotifier<bool> {
  BoolPrefNotifier(this._prefs, this._key, {bool defaultValue = false})
      : super(_prefs.getBool(_key) ?? defaultValue);

  final SharedPreferences _prefs;
  final String _key;

  Future<void> setValue(bool value) async {
    state = value;
    await _prefs.setBool(_key, value);
  }
}

/// "Flouter la plaque lors de l'export" toggle.
final StateNotifierProvider<BoolPrefNotifier, bool> blurPlateOnExportProvider =
    StateNotifierProvider<BoolPrefNotifier, bool>(
  (Ref ref) => BoolPrefNotifier(ref.watch(sharedPreferencesProvider), AppConstants.prefBlurPlateOnExport),
);

/// "Conserver la photo originale" toggle: when off, only a compact
/// thumbnail-quality copy is kept on disk for new captures.
final StateNotifierProvider<BoolPrefNotifier, bool> keepOriginalPhotoProvider =
    StateNotifierProvider<BoolPrefNotifier, bool>(
  (Ref ref) => BoolPrefNotifier(
    ref.watch(sharedPreferencesProvider),
    AppConstants.prefKeepOriginalPhoto,
    defaultValue: true,
  ),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static ThemeMode _load(SharedPreferences prefs) {
    final String? raw = prefs.getString(AppConstants.prefThemeMode);
    return ThemeMode.values.firstWhere((ThemeMode m) => m.name == raw, orElse: () => ThemeMode.system);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(AppConstants.prefThemeMode, mode.name);
  }
}

final StateNotifierProvider<ThemeModeNotifier, ThemeMode> themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (Ref ref) => ThemeModeNotifier(ref.watch(sharedPreferencesProvider)),
);

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Locale? _load(SharedPreferences prefs) {
    final String? raw = prefs.getString(AppConstants.prefLocale);
    return raw == null ? null : Locale(raw);
  }

  /// `null` means "follow the system locale".
  Future<void> setLocale(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await _prefs.remove(AppConstants.prefLocale);
    } else {
      await _prefs.setString(AppConstants.prefLocale, locale.languageCode);
    }
  }
}

final StateNotifierProvider<LocaleNotifier, Locale?> localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>(
  (Ref ref) => LocaleNotifier(ref.watch(sharedPreferencesProvider)),
);

final Provider<PrivacyService> privacyServiceProvider = Provider<PrivacyService>(
  (Ref ref) => PrivacyServiceImpl(
    ref.watch(sharedPreferencesProvider),
    ref.watch(captureRepositoryProvider),
    ref.watch(cameraServiceProvider),
  ),
);

final Provider<ExportService> exportServiceProvider = Provider<ExportService>(
  (Ref ref) => ExportServiceImpl(ref.watch(privacyServiceProvider)),
);
