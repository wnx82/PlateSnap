import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../presentation/providers/settings_providers.dart';
import '../../privacy/presentation/widgets/privacy_content.dart';

/// First-launch privacy notice. Shown once; the user must explicitly
/// acknowledge it before reaching the home screen.
class PrivacyOnboardingScreen extends ConsumerWidget {
  const PrivacyOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: <Widget>[
              const Expanded(child: SingleChildScrollView(child: PrivacyContent())),
              FilledButton(
                onPressed: () async {
                  await ref.read(privacyServiceProvider).setHasSeenPrivacyIntro(true);
                  ref.read(hasSeenPrivacyIntroProvider.notifier).state = true;
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(l10n.privacyContinue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
