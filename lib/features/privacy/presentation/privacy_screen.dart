import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import 'widgets/privacy_content.dart';

/// Privacy page reachable at any time from Settings (as opposed to
/// [PrivacyOnboardingScreen], which only appears once on first launch).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: PrivacyContent(),
      ),
    );
  }
}
