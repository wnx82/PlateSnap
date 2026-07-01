import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';

/// Placeholder settings screen. Replaced with language/theme/export/privacy
/// controls in a later branch.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: const Center(child: Icon(Icons.settings, size: 64)),
    );
  }
}
