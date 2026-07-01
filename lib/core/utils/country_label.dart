import '../constants/app_constants.dart';
import '../l10n/generated/app_localizations.dart';

/// Full, localized country name (e.g. "Belgique") for [country], as opposed
/// to [PlateCountryLabel.badgeLabel] which is the short "BE"/"FR"/"?" chip
/// text.
String countryDisplayName(AppLocalizations l10n, PlateCountry country) {
  return switch (country) {
    PlateCountry.be => l10n.countryBelgium,
    PlateCountry.fr => l10n.countryFrance,
    PlateCountry.unknown => l10n.countryUnknown,
  };
}
