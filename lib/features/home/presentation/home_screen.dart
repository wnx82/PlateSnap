import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../capture/presentation/capture_flow.dart';

/// App entry screen: quick actions (new capture, history, settings) and a
/// summary of the local capture history.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _SummaryCard(),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => openCaptureFlow(context, ref),
                icon: const Icon(Icons.camera_alt),
                label: Text(l10n.homeNewCapture),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openHistory(context),
                icon: const Icon(Icons.history),
                label: Text(l10n.homeHistory),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openSettings(context),
                icon: const Icon(Icons.settings),
                label: Text(l10n.homeSettings),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).pushNamed('/history');
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/settings');
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(l10n.homeSummaryTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(l10n.homeNoCaptureYet, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
