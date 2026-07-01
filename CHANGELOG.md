# Changelog

Toutes les modifications notables de PlateSnap seront documentées ici.

Le projet suit le Semantic Versioning : MAJOR.MINOR.PATCH.

## [Unreleased]

## [0.4.0] - 2026-07-01

### Added

- `PlateRecognitionEngine` : moteur pur (sans dépendance Flutter/OCR) de nettoyage OCR et de correspondance de formats, entièrement testable en isolation.
  - Formats belges modernes : `1-ABC-123` / `2-ABC-123`, variante sans tirets `1ABC123`.
  - Format français SIV : `AB-123-CD`, variante sans tirets `AB123CD`.
  - Retourne `unknown` si aucun format ne correspond, en conservant toujours le texte OCR brut.
  - Nettoyage des espaces/caractères parasites et correction ciblée des confusions OCR fréquentes (`O↔0`, `I↔1`, `B↔8`, `S↔5`, `Z↔2`), appliquée uniquement quand un caractère ne correspond pas au type attendu (chiffre/lettre) de sa position, pour éviter toute sur-correction.
- `PlateRecognitionServiceImpl` : reconnaissance de texte on-device via `google_mlkit_text_recognition` (aucun appel réseau), déléguant l'analyse au moteur pur ci-dessus.
- Écran d'analyse transitoire (`AnalyzingScreen`) exécutant en parallèle la localisation GPS et la reconnaissance de plaque après confirmation de la photo.
- Écran de validation enrichi : plaque détectée, badge pays, score de confiance, candidats alternatifs, texte OCR brut consultable, et correction manuelle complète de la plaque avant enregistrement.
- Widget partagé `CountryBadge` (BE/FR/Inconnu) réutilisable dans l'historique et le détail.

### Changed

- Le flux de capture inclut désormais l'étape d'analyse (localisation + OCR) avant d'afficher l'écran de validation.

### Fixed

## [0.3.0] - 2026-07-01

### Added

- `LocationService` (implémentation `LocationServiceImpl` via `geolocator`) : permission de localisation, statut du service GPS, position ponctuelle (jamais de suivi continu).
- Permissions de localisation déclarées côté Android (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`) et iOS (`NSLocationWhenInUseUsageDescription`).
- Entité transitoire `DraftCapture` représentant une capture entre la prise de photo et son enregistrement définitif.
- Écran de validation (`ValidationScreen`) affichant la photo, la date, l'heure locale et la position GPS (ou un message clair si indisponible/refusée), avec actions "Enregistrer", "Reprendre la photo", "Annuler".
- Orchestration du flux complet capture → localisation → validation (`capture_flow.dart`), sans logique de navigation dans les écrans eux-mêmes.

### Changed

- `HomeScreen` déclenche désormais le flux de capture complet (caméra puis validation) au lieu de revenir directement à l'accueil.

### Fixed

## [0.2.0] - 2026-07-01

### Added

- Écran d'accueil (`HomeScreen`) avec les actions "Nouvelle capture", "Historique", "Paramètres" et une carte de résumé.
- Flux de capture caméra complet (`CaptureScreen`) : demande de permission caméra avec message clair, aperçu caméra live (package `camera`), prise de photo, écran de relecture (reprendre/valider).
- `CameraService` (implémentation `CameraServiceImpl`) : permissions caméra, persistance des photos capturées dans le stockage local de l'app, génération de miniatures.
- Permissions caméra déclarées côté Android (`AndroidManifest.xml`) et iOS (`Info.plist` `NSCameraUsageDescription`).
- Écrans temporaires Historique/Paramètres (finalisés dans des branches ultérieures) pour permettre la navigation complète dès maintenant.

### Changed

### Fixed

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
