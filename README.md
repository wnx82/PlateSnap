# PlateSnap

Application mobile Flutter (Android/iOS) permettant de photographier une
plaque d'immatriculation, de la reconnaître automatiquement (OCR
on-device, formats belges et français en priorité, autres formats
européens en best-effort), d'enregistrer la date, l'heure et la
géolocalisation de la prise de vue, puis de consulter, corriger et
exporter l'historique des captures. **100 % hors ligne, 100 % local.**

## Objectifs

- Capture manuelle uniquement : aucune détection automatique en arrière-plan, aucun scan permanent.
- Reconnaissance de plaque on-device (Belgique / France en priorité, autres formats européens en best-effort).
- Enregistrement automatique de la date, l'heure locale et la position GPS de la capture.
- Historique consultable, filtrable, exportable, avec suppression individuelle ou totale.
- Confidentialité par conception : stockage local uniquement, aucun envoi réseau automatique.

## Captures fonctionnelles prévues (V1)

1. **Accueil** — résumé (nombre de captures, dernière capture, confiance OCR moyenne), accès rapide à une nouvelle capture, à l'historique et aux paramètres.
2. **Nouvelle capture** — permissions caméra/localisation, prise de photo, analyse OCR automatique.
3. **Validation** — relecture de la plaque détectée, correction manuelle, confirmation avant enregistrement.
4. **Historique** — liste des captures avec recherche, filtres (pays, date), tri du plus récent au plus ancien.
5. **Détail** — photo, plaque (détectée/corrigée), position GPS, note libre, export, ouverture dans Maps.
6. **Paramètres** — langue, thème, floutage de plaque à l'export, conservation de la photo originale, export global CSV/JSON, suppression totale, page confidentialité.

## Stack technique

| Domaine | Choix |
|---|---|
| Framework | Flutter (Dart, SDK ^3.9) |
| Architecture | Clean-ish layering : `core`, `domain`, `data`, `features`, `presentation` |
| Gestion d'état | Riverpod (`flutter_riverpod`) |
| Caméra | package [`camera`](https://pub.dev/packages/camera) |
| Géolocalisation | package [`geolocator`](https://pub.dev/packages/geolocator) |
| OCR on-device | package [`google_mlkit_text_recognition`](https://pub.dev/packages/google_mlkit_text_recognition) (ML Kit exécuté localement sur l'appareil, aucun appel réseau) |
| Stockage local | SQLite via [`drift`](https://pub.dev/packages/drift) + `sqlite3_flutter_libs` |
| Permissions | [`permission_handler`](https://pub.dev/packages/permission_handler) |
| Export | [`csv`](https://pub.dev/packages/csv), `dart:convert` (JSON), [`share_plus`](https://pub.dev/packages/share_plus) |
| i18n | `flutter_localizations` + fichiers `.arb` (FR par défaut, EN, NL) |
| Tests | `flutter_test`, `mocktail` |

Aucune fonctionnalité de la V1 ne dépend d'une API cloud. L'application
fonctionne intégralement hors connexion.

## Installation

Prérequis : Flutter SDK stable (>= 3.35), Android Studio / Xcode selon la
plateforme cible.

```bash
git clone <url-du-repo>
cd PlateSnap
flutter pub get
flutter gen-l10n
```

Si le projet utilise des fichiers générés par `drift`/`build_runner` :

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Lancement Android

```bash
flutter devices                 # vérifier qu'un émulateur/appareil Android est détecté
flutter run -d <device-id>
```

Un appareil physique est recommandé pour tester la caméra et le GPS
(les émulateurs simulent mal l'appareil photo réel).

## Lancement iOS

```bash
cd ios && pod install && cd ..
flutter run -d <device-id>
```

Nécessite macOS + Xcode. Un compte développeur Apple est requis pour
déployer sur un appareil physique.

## Structure du projet

```
lib/
  core/                 # thème, constantes, erreurs, i18n, routing, utils
  domain/                # entités et interfaces de service (indépendantes de Flutter/plugins)
    entities/
    services/            # CameraService, LocationService, PlateRecognitionService, ExportService, PrivacyService
    repositories/         # CaptureRepository (interface)
  data/                 # implémentations concrètes (drift, ML Kit, geolocator, camera...)
    local/                # base de données SQLite (drift)
    repositories/
    services/
  features/             # un dossier par écran/fonctionnalité
    home/
    capture/
    validation/
    history/
    capture_detail/
    settings/
    privacy/
    onboarding/
  presentation/         # widgets partagés, providers Riverpod globaux
test/
  unit/                 # tests de services (reconnaissance de plaque, repository...)
  widget/               # tests d'écrans
```

## Permissions utilisées

| Permission | Usage | Comportement si refusée |
|---|---|---|
| Caméra | Prendre la photo de la plaque | Message clair + bouton pour ouvrir les réglages système ; aucune capture possible sans caméra |
| Localisation (au premier plan uniquement) | Enregistrer latitude/longitude/précision de la capture | La capture est enregistrée sans coordonnées GPS, avec un avertissement |

Aucune permission d'arrière-plan n'est demandée : la localisation n'est
lue qu'au moment précis d'une capture déclenchée manuellement.

## Fonctionnement de la reconnaissance de plaques

`PlateRecognitionService` (interface dans `domain/services`, implémentation
dans `data/services`) :

1. Lance l'OCR on-device (ML Kit Text Recognition) sur la photo.
2. Nettoie le texte brut (suppression des espaces/caractères parasites,
   normalisation des tirets, corrections de confusions OCR fréquentes :
   `O↔0`, `I↔1`, `B↔8`, `S↔5`, `Z↔2`) — **sans écraser le texte brut**,
   qui reste toujours disponible pour correction manuelle.
3. Recherche les formats de plaques connus :
   - **Belgique** : `1-ABC-123` / `2-ABC-123` (formats récents), variante sans tirets `1ABC123`.
   - **France (SIV)** : `AB-123-CD`, variante sans tirets `AB123CD`.
   - Aucun format reconnu → pays retourné : `unknown`, texte OCR brut conservé pour saisie manuelle.
4. Retourne un `PlateRecognitionResult` : texte OCR brut, plaque détectée,
   pays probable, score de confiance, liste de candidats alternatifs.

La couche est volontairement simple en V1 (OCR + règles) mais conçue pour
être remplacée/complétée par un modèle de détection ML dédié sans changer
les appelants (voir Roadmap).

## Limites de la reconnaissance OCR

- Dépend fortement de la qualité de la photo (lumière, angle, flou, plaque sale ou partiellement masquée).
- Les formats autres que BE/FR modernes sont gérés en best-effort et peuvent être retournés comme `unknown`.
- Les anciens formats de plaques belges/français ne sont pas couverts en V1.
- Le score de confiance est purement heuristique (basé sur la qualité du match de format, voir Hypothèses techniques), pas une probabilité calibrée issue de l'OCR.
- **La correction manuelle reste indispensable avant tout usage sensible du résultat.**

## Confidentialité

- Stockage **local uniquement** : photos, plaques, positions GPS et
  historique ne quittent jamais l'appareil automatiquement.
- **Aucune synchronisation cloud**, aucun compte utilisateur, aucun tracker.
- **Aucun envoi de données externe** sans action explicite (un export
  CSV/JSON déclenché et partagé volontairement par l'utilisateur).
- Écran de confidentialité affiché au premier lancement (`features/onboarding`),
  accessible à tout moment depuis les paramètres.
- Permissions demandées avec justification claire, uniquement au moment
  où elles sont nécessaires.
- Suppression possible d'une capture individuelle ou de tout l'historique
  (photos + thumbnails + base de données) depuis les paramètres.
- Option de floutage de la plaque sur les photos exportées.
- **Aucune fonctionnalité de surveillance automatique** : pas de scan
  permanent, pas de suivi continu d'utilisateurs ou de véhicules — chaque
  capture est déclenchée manuellement.

## Stockage local

- Base de données SQLite gérée via `drift` (`data/local/app_database.dart`),
  table `capture_records` reflétant l'entité `CaptureRecord`.
- Photos et miniatures stockées dans le répertoire de documents de
  l'application (`path_provider`), jamais dans un dossier public partagé.
- Aucune donnée n'est chiffrée par défaut en V1 (voir Roadmap :
  "sauvegarde chiffrée").

## Export CSV/JSON

- Export global (tout l'historique) ou export d'une capture unique, depuis
  les paramètres ou l'écran de détail.
- Formats : CSV (tableur) et JSON (ré-import/interopérabilité).
- Option "flouter la plaque" applicable à l'export des photos.
- Le fichier généré est ensuite partagé via la feuille de partage native
  du système (`share_plus`) — c'est le seul moyen pour une donnée de
  quitter l'appareil, et il est toujours initié par l'utilisateur.

## Versioning

Le projet suit [Semantic Versioning](https://semver.org/) : `MAJOR.MINOR.PATCH`.
La version courante est disponible dans le fichier [`VERSION`](VERSION) et
dans `pubspec.yaml`.

## Changelog

Voir [`CHANGELOG.md`](CHANGELOG.md) pour l'historique détaillé des
modifications, organisé par version.

## Commandes Git utiles

```bash
git checkout -b feature/x.y.z-nom-de-la-fonctionnalite   # créer une branche de fonctionnalité
git add <fichiers>
git commit -m "feat(scope): description"
git checkout main && git merge --no-ff feature/x.y.z-nom # fusionner dans main
git tag -a vx.y.z -m "Release x.y.z"                      # taguer une version
git log --oneline --graph --decorate                      # historique visuel
```

## Commandes de test

```bash
flutter analyze                # analyse statique
flutter test                   # tests unitaires + widgets
flutter test --coverage        # avec couverture (rapport dans coverage/)
```

> Note (Linux desktop uniquement) : les tests qui exercent la base de
> données locale (`drift`/`sqlite3`) nécessitent `libsqlite3` sur la
> machine hôte. Sur Debian/Ubuntu : `sudo apt-get install libsqlite3-0`,
> puis, si seule la bibliothèque versionnée (`libsqlite3.so.0`) est
> présente, les tests concernés utilisent
> `open.overrideFor(OperatingSystem.linux, ...)` du package `sqlite3`
> pour la charger explicitement. Sur Android/iOS réels, `sqlite3_flutter_libs`
> embarque la bibliothèque native : aucune action n'est nécessaire.

## CI locale

Un script simple regroupant analyse statique + tests est fourni :
[`tool/ci.sh`](tool/ci.sh).

```bash
./tool/ci.sh
```

Il exécute, dans l'ordre, `flutter pub get`, `flutter analyze` et
`flutter test`, et s'arrête au premier échec — à lancer avant chaque
commit important ou fusion vers `main`.

## Roadmap

- Reconnaissance de plaques plus avancée avec un modèle ML dédié (détection + OCR spécialisé plaque).
- Carte des captures (visualisation géographique de l'historique).
- Sauvegarde chiffrée de la base locale et des photos.
- Synchronisation optionnelle (opt-in explicite, chiffrée de bout en bout).
- Authentification biométrique pour protéger l'accès à l'historique.
- Export PDF.
- Mode entreprise/flotte (multi-utilisateurs, tags de véhicules).
- Statistiques avancées (captures par pays, par période, cartes de chaleur).
- Amélioration de la couverture des formats de plaques européens (formats historiques, autres pays).

## Hypothèses techniques

Ce projet ayant été généré de façon autonome, les hypothèses suivantes ont
été prises lorsqu'une information n'était pas spécifiée :

- **OCR** : ML Kit Text Recognition (Google) a été choisi comme moteur OCR
  on-device car il est gratuit, maintenu, fonctionne hors ligne après le
  premier téléchargement du modèle par le système, et dispose d'un
  package Flutter officiel maintenu. Alternative documentée mais non
  utilisée : Tesseract via `tesseract_ocr` (moins bien maintenu côté Flutter).
- **Formats de plaques belges "modernes"** : `1-ABC-123` / `2-ABC-123`
  (un chiffre, trois lettres, trois chiffres) tels que fournis dans la
  consigne ; les formats antérieurs (ex. plaques rouges/marchand) ne sont
  pas couverts en V1.
- **Format français SIV** : `AB-123-CD` (deux lettres, trois chiffres,
  deux lettres), en vigueur depuis 2009 ; l'ancien format FNI
  (`123 ABC 75`) n'est pas couvert en V1.
- **Score de confiance** : `google_mlkit_text_recognition` n'expose pas de
  confiance fiable par caractère sur toutes les plateformes ; le score
  retourné est donc purement heuristique, basé sur le moteur de formats
  (`PlateRecognitionEngine`) : une correspondance stricte avec tirets vaut
  0.95, sans tirets 0.85, et chaque correction de confusion OCR appliquée
  (`O↔0`, etc.) réduit ce score de 0.10 (plancher 0.5). Ce n'est pas une
  probabilité calibrée statistiquement.
- **Reverse geocoding** : non inclus en V1 (nécessiterait soit un service
  cloud, soit une base de données offline volumineuse) ; l'historique
  affiche latitude/longitude, avec un lien direct vers Maps.
- **Thème par défaut** : suit le thème système (clair/sombre), modifiable
  manuellement dans les paramètres.
- **Langue par défaut** : français, avec structure i18n prête pour
  anglais et néerlandais (`lib/core/l10n/arb/`).
- **Package caméra** : le package `camera` officiel a été préféré à
  `image_picker` pour garder le contrôle sur la qualité/résolution de la
  capture et permettre une future extension (ex. cadrage guidé de la
  plaque), au prix d'une intégration légèrement plus complexe.
- **Aucun compte utilisateur** n'est requis ni proposé en V1, cohérent
  avec l'exigence "aucune synchronisation cloud automatique".
- **Floutage de la plaque à l'export** : la position exacte de la plaque
  dans l'image n'est pas conservée par le pipeline OCR actuel (ML Kit ne
  garantit pas un bloc de texte unique et fiable pour la plaque). Le
  floutage (`PrivacyService.blurPlateRegion`) applique donc un flou
  gaussien sur une zone heuristique du bas-centre de la photo (l'endroit
  où la plaque se trouve le plus souvent), plutôt que sur une zone
  détectée précisément. L'interface prévoit néanmoins un paramètre
  `PlateBoundingBox` optionnel pour un floutage précis, dès qu'une
  détection de zone fiable sera disponible (voir Roadmap).
- **Option "conserver la photo originale"** : interprétée comme un
  réglage de stockage local (et non d'export) — lorsqu'elle est
  désactivée, seule une copie compacte (la miniature) est conservée sur
  disque pour les nouvelles captures, la photo pleine résolution étant
  supprimée immédiatement après la génération de la miniature.

## Licence

Voir [`LICENSE`](LICENSE).
