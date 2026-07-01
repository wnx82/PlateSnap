import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';

/// Small colored "BE" / "FR" / "?" chip used anywhere a capture's country is
/// shown (validation, history, detail).
class CountryBadge extends StatelessWidget {
  const CountryBadge({super.key, required this.country});

  final PlateCountry country;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (country) {
      PlateCountry.be => (Colors.amber.shade700, Colors.white),
      PlateCountry.fr => (Colors.blue.shade700, Colors.white),
      PlateCountry.unknown => (Colors.grey.shade500, Colors.white),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16)),
      child: Text(
        country.badgeLabel,
        style: TextStyle(color: foreground, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
