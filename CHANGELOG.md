# Changelog

Toutes les modifications notables de PlateSnap seront documentées ici.

Le projet suit le Semantic Versioning : MAJOR.MINOR.PATCH.

## [Unreleased]

## [0.8.0] - 2026-07-01

### Added

- Tests unitaires de `PlateRecognitionEngine` : formats belges/français avec et sans tirets, cas `unknown`, nettoyage des espaces/caractères parasites, corrections de confusions OCR, non-sur-correction.
- Tests unitaires de `CaptureRepositoryImpl` (base SQLite en mémoire) : création/lecture, suppression individuelle et totale, filtre par pays, recherche par plaque, tri, statistiques.
- Tests widgets : écran d'accueil, écran de validation (plaque détectée, saisie manuelle, enregistrement), écran d'historique (état vide, liste, recherche), écran de détail (affichage, confirmation de suppression, édition).
- Aides de test partagées (`test/test_helpers/`) : mocks Mocktail des services/repository, wrapper `pumpApp` avec un viewport de test de taille téléphone.

### Changed

- `ValidationScreen` affiche désormais le message "aucune plaque détectée" même lorsque le champ de saisie manuelle est déjà actif (l'affichage précédent masquait ce message dès l'entrée en mode édition automatique).

### Fixed

- Correction d'un import inutilisé détecté par l'analyse statique.

## [0.7.0] - 2026-07-01

### Added

- `PrivacyServiceImpl` : préférences de confidentialité persistées localement (intro vue, floutage à l'export, conservation de la photo originale), floutage gaussien on-device d'une zone de la plaque, suppression totale des données (base + fichiers photo/miniatures).
- `ExportServiceImpl` : export global CSV et JSON de tout l'historique, export d'une capture unique (JSON + photo, floutée si l'option est activée), tous écrits localement puis partagés via la feuille de partage native.
- Écran de confidentialité (`PrivacyScreen`) accessible depuis les paramètres, et écran d'accueil de confidentialité au premier lancement (`PrivacyOnboardingScreen`), affiché avant tout accès à l'application.
- Écran Paramètres complet : langue (Système/FR/EN/NL), thème (Système/Clair/Sombre), floutage à l'export, conservation de la photo originale, lien confidentialité, export CSV/JSON global, suppression totale de l'historique (avec confirmation).
- Bouton "Exporter cette capture" sur l'écran de détail.
- Comportement réel de "conserver la photo originale" : lorsqu'il est désactivé, seule la miniature est conservée sur disque pour les nouvelles captures.

### Changed

### Fixed

## [0.6.0] - 2026-07-01

### Added

- Écran Historique complet : recherche par plaque, filtre par pays (BE/FR/Autre/Tous), filtre par date, tri du plus récent au plus ancien (par défaut), suppression individuelle avec confirmation, état vide dédié.
- Widget `CaptureCard` : miniature, plaque, badge pays, date/heure, coordonnées GPS.
- Écran de détail d'une capture (`CaptureDetailScreen`) : photo, plaque détectée/corrigée, pays, date/heure, GPS et précision, note libre éditable, bouton "Ouvrir dans Maps", modification et suppression (avec nettoyage des fichiers photo/miniature).
- Dialogue de confirmation partagé (`showConfirmDialog`) réutilisé pour toutes les suppressions.

### Changed

### Fixed

## [0.5.0] - 2026-07-01

### Added

- Base de données SQLite locale via `drift` (`AppDatabase`, table `capture_records`), stockée dans le répertoire de documents privé de l'application.
- `CaptureRepositoryImpl` : création, lecture, mise à jour, suppression (unitaire et totale), recherche par plaque, filtre par pays/date, statistiques agrégées (`watchStats`), le tout en flux réactifs (`Stream`) pour l'UI.
- Persistance réelle du flux de capture : à l'enregistrement, la miniature est générée puis la capture (photo, plaque, pays, confiance, GPS, date/heure) est écrite en base.
- Carte de résumé de l'accueil connectée aux statistiques réelles (nombre total de captures, dernière capture, confiance OCR moyenne).
- `AppDatabase.withExecutor` pour permettre l'injection d'une base en mémoire dans les tests (branche tests à venir).

### Changed

- `HomeScreen` redevient réactif (Riverpod) pour afficher les statistiques en direct.

### Fixed

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
