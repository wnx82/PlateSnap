import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../domain/entities/draft_capture.dart';

/// Lets the user review a freshly captured photo together with its
/// automatically-collected metadata (date, time, GPS) before it is
/// persisted. Plate recognition and manual correction are layered on top
/// of this screen in a later branch, once [DraftCapture.recognition] is
/// populated.
class ValidationScreen extends StatelessWidget {
  const ValidationScreen({
    super.key,
    required this.draft,
    required this.onSave,
    required this.onRetake,
    required this.onCancel,
  });

  final DraftCapture draft;
  final VoidCallback onSave;
  final VoidCallback onRetake;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String localeName = Localizations.localeOf(context).toString();
    final DateFormat dateFormat = DateFormat.yMMMMd(localeName);
    final DateFormat timeFormat = DateFormat.Hms(localeName);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.validationTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.file(File(draft.imagePath), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          _InfoTile(icon: Icons.event, label: l10n.validationDate, value: dateFormat.format(draft.capturedAt)),
          _InfoTile(icon: Icons.access_time, label: l10n.validationTime, value: timeFormat.format(draft.capturedAt)),
          _LocationTile(draft: draft, l10n: l10n),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetake,
                  icon: const Icon(Icons.replay),
                  label: Text(l10n.validationRetake),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close),
                  label: Text(l10n.validationCancel),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save),
            label: Text(l10n.validationSave),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({required this.draft, required this.l10n});

  final DraftCapture draft;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final String subtitle;
    if (draft.gpsPosition != null) {
      final double lat = draft.gpsPosition!.latitude;
      final double lng = draft.gpsPosition!.longitude;
      final double? accuracy = draft.gpsPosition!.accuracyMeters;
      subtitle = accuracy != null
          ? '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)} (±${accuracy.toStringAsFixed(0)} m)'
          : '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
    } else if (draft.locationPermissionDenied) {
      subtitle = l10n.errorLocationPermissionDenied;
    } else {
      subtitle = l10n.errorLocationUnavailable;
    }
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.location_on_outlined),
      title: Text(l10n.validationLocation),
      subtitle: Text(subtitle),
    );
  }
}
