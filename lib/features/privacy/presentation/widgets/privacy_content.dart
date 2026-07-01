import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';

/// Body text of the privacy notice, shared between the first-launch
/// onboarding screen and the always-available privacy page in settings.
class PrivacyContent extends StatelessWidget {
  const PrivacyContent({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(Icons.privacy_tip_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(l10n.privacyIntro, style: textTheme.titleLarge),
        const SizedBox(height: 16),
        _bullet(context, Icons.smartphone, l10n.privacyBody1),
        _bullet(context, Icons.cloud_off, l10n.privacyBody2),
        _bullet(context, Icons.videocam_off, l10n.privacyBody3),
        _bullet(context, Icons.delete_outline, l10n.privacyBody4),
      ],
    );
  }

  Widget _bullet(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
