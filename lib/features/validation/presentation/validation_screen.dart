import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/utils/country_label.dart';
import '../../../domain/entities/draft_capture.dart';
import '../../../domain/services/plate_recognition_service.dart';
import '../../../presentation/widgets/country_badge.dart';

/// Lets the user review a freshly captured photo together with its
/// automatically-collected metadata (date, time, GPS, detected plate) and
/// correct the plate manually before it is persisted.
class ValidationScreen extends StatefulWidget {
  const ValidationScreen({
    super.key,
    required this.draft,
    required this.onSave,
    required this.onRetake,
    required this.onCancel,
  });

  final DraftCapture draft;

  /// Called with the final corrected plate text (may equal the detected
  /// plate, or be empty if none was ever provided). May throw/report errors
  /// via a SnackBar using the given context; the screen stays open on
  /// failure so the user can retry.
  final Future<void> Function(BuildContext context, String correctedPlate) onSave;
  final VoidCallback onRetake;
  final VoidCallback onCancel;

  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  late final TextEditingController _plateController;
  bool _isEditingPlate = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final String initial = widget.draft.correctedPlate ?? widget.draft.recognition?.detectedPlate ?? '';
    _plateController = TextEditingController(text: initial);
    _isEditingPlate = !widget.draft.hasUsablePlate;
  }

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _handleSave(BuildContext context) async {
    setState(() => _isSaving = true);
    await widget.onSave(context, _plateController.text.trim());
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String localeName = Localizations.localeOf(context).toString();
    final DateFormat dateFormat = DateFormat.yMMMMd(localeName);
    final DateFormat timeFormat = DateFormat.Hms(localeName);
    final PlateRecognitionResult? recognition = widget.draft.recognition;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.validationTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.file(File(widget.draft.imagePath), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          _buildPlateSection(context, l10n, recognition),
          const Divider(height: 32),
          _InfoTile(icon: Icons.event, label: l10n.validationDate, value: dateFormat.format(widget.draft.capturedAt)),
          _InfoTile(icon: Icons.access_time, label: l10n.validationTime, value: timeFormat.format(widget.draft.capturedAt)),
          _LocationTile(draft: widget.draft, l10n: l10n),
          const SizedBox(height: 24),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onRetake,
                  icon: const Icon(Icons.replay),
                  label: Text(l10n.validationRetake),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close),
                  label: Text(l10n.validationCancel),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isSaving ? null : () => _handleSave(context),
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            label: Text(l10n.validationSave),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlateSection(BuildContext context, AppLocalizations l10n, PlateRecognitionResult? recognition) {
    final bool hasAutoPlate = recognition != null && recognition.hasDetectedPlate;
    final PlateCountry country = recognition?.countryCode ?? PlateCountry.unknown;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(l10n.validationDetectedPlate, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            CountryBadge(country: country),
          ],
        ),
        const SizedBox(height: 8),
        if (!hasAutoPlate) ...<Widget>[
          Text(l10n.validationNoPlateDetected, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
        ],
        if (_isEditingPlate)
          TextField(
            controller: _plateController,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: l10n.validationDetectedPlate,
            ),
            onChanged: (_) => setState(() {}),
          )
        else
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _plateController.text,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _isEditingPlate = true),
                icon: const Icon(Icons.edit),
                label: Text(l10n.validationEditPlate),
              ),
            ],
          ),
        if (hasAutoPlate) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            '${l10n.validationCountry}: ${countryDisplayName(l10n, country)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (recognition.confidence != null)
            Text(
              '${l10n.validationConfidence}: ${(recognition.confidence! * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
        if (recognition != null && recognition.candidates.length > 1) ...<Widget>[
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l10n.validationCandidates, style: Theme.of(context).textTheme.bodyMedium),
            children: recognition.candidates
                .skip(1)
                .map(
                  (PlateCandidate c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CountryBadge(country: c.countryCode),
                    title: Text(c.text),
                    trailing: Text('${(c.confidence * 100).toStringAsFixed(0)}%'),
                    onTap: () => setState(() {
                      _plateController.text = c.text;
                      _isEditingPlate = false;
                    }),
                  ),
                )
                .toList(),
          ),
        ],
        if (recognition != null) ...<Widget>[
          const SizedBox(height: 4),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l10n.validationRawOcr, style: Theme.of(context).textTheme.bodyMedium),
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SelectableText(
                    recognition.rawOcrText.isEmpty ? '—' : recognition.rawOcrText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
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
