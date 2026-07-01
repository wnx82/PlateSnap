# Changelog

Toutes les modifications notables de PlateSnap seront documentées ici.

Le projet suit le Semantic Versioning : MAJOR.MINOR.PATCH.

## [Unreleased]

## [0.1.0] - 2026-07-01

### Added

- Initialisation du projet Flutter (Android/iOS) avec architecture propre : `core`, `domain`, `data`, `features`, `presentation`.
- Dépendances principales : Riverpod, camera, geolocator, google_mlkit_text_recognition, drift/sqlite3, permission_handler, share_plus, csv, shared_preferences.
- Squelette d'internationalisation (FR par défaut, EN et NL) via `flutter gen-l10n`.
- Thème Material 3 clair/sombre.
- Interfaces de domaine : `CameraService`, `LocationService`, `PlateRecognitionService`, `CaptureRepository`, `ExportService`, `PrivacyService`.
- Entité de domaine `CaptureRecord`.
- Hiérarchie d'erreurs applicatives (`AppException` et sous-types) pour des messages utilisateur clairs.
- README, CHANGELOG, VERSION, `.gitignore`.

### Changed

### Fixed
