/// Global, hard-coded constants for PlateSnap.
class AppConstants {
  AppConstants._();

  static const String appName = 'PlateSnap';
  static const String appVersion = '0.1.0';

  static const String capturesDirectoryName = 'captures';
  static const String thumbnailsDirectoryName = 'thumbnails';
  static const int thumbnailMaxDimension = 320;

  static const String prefHasSeenPrivacyIntro = 'has_seen_privacy_intro';
  static const String prefThemeMode = 'theme_mode';
  static const String prefLocale = 'locale';
  static const String prefBlurPlateOnExport = 'blur_plate_on_export';
  static const String prefKeepOriginalPhoto = 'keep_original_photo';
}

/// Country codes recognized by [PlateRecognitionService].
enum PlateCountry { be, fr, unknown }

extension PlateCountryLabel on PlateCountry {
  String get badgeLabel => switch (this) {
        PlateCountry.be => 'BE',
        PlateCountry.fr => 'FR',
        PlateCountry.unknown => '?',
      };
}
