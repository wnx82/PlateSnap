import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/utils/country_label.dart';
import '../../../core/utils/error_messages.dart';
import '../../../domain/entities/capture_record.dart';
import '../../../domain/services/export_service.dart';
import '../../../presentation/providers/repository_providers.dart';
import '../../../presentation/providers/service_providers.dart';
import '../../../presentation/providers/settings_providers.dart';
import '../../../presentation/widgets/confirm_dialog.dart';
import '../../../presentation/widgets/country_badge.dart';

/// Full detail view of a single capture: photo, plate (with manual
/// correction), country, date/time, GPS, a free-form note, and delete /
/// open-in-Maps actions.
class CaptureDetailScreen extends ConsumerStatefulWidget {
  const CaptureDetailScreen({super.key, required this.captureId});

  final String captureId;

  @override
  ConsumerState<CaptureDetailScreen> createState() => _CaptureDetailScreenState();
}

class _CaptureDetailScreenState extends ConsumerState<CaptureDetailScreen> {
  CaptureRecord? _record;
  bool _loading = true;
  bool _isEditing = false;
  late final TextEditingController _plateController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _plateController = TextEditingController();
    _noteController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _plateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final CaptureRecord? record = await ref.read(captureRepositoryProvider).getById(widget.captureId);
      if (!mounted) return;
      setState(() {
        _record = record;
        _plateController.text = record?.displayPlate ?? '';
        _noteController.text = record?.note ?? '';
        _loading = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      final AppLocalizations l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appExceptionMessage(l10n, e))));
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final CaptureRecord? current = _record;
    if (current == null) return;
    final String newPlate = _plateController.text.trim();
    final String newNote = _noteController.text.trim();
    final CaptureRecord updated = current.copyWith(
      correctedPlate: newPlate,
      clearCorrectedPlate: newPlate.isEmpty || newPlate == current.detectedPlate,
      note: newNote,
      clearNote: newNote.isEmpty,
      updatedAt: DateTime.now(),
    );
    try {
      await ref.read(captureRepositoryProvider).update(updated);
      if (!mounted) return;
      setState(() {
        _record = updated;
        _isEditing = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      final AppLocalizations l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appExceptionMessage(l10n, e))));
    }
  }

  Future<void> _delete() async {
    final CaptureRecord? current = _record;
    if (current == null) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool confirmed = await showConfirmDialog(
      context,
      title: l10n.historyDeleteConfirmTitle,
      message: l10n.historyDeleteConfirmMessage,
      confirmLabel: l10n.actionDelete,
      cancelLabel: l10n.actionCancel,
    );
    if (!confirmed) return;
    try {
      await ref.read(captureRepositoryProvider).delete(current.id);
      await ref.read(cameraServiceProvider).deleteImage(
            imagePath: current.imagePath,
            thumbnailPath: current.thumbnailPath,
          );
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appExceptionMessage(l10n, e))));
    }
  }

  Future<void> _openInMaps() async {
    final CaptureRecord? current = _record;
    if (current == null || !current.hasLocation) return;
    final Uri uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${current.latitude},${current.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _export() async {
    final CaptureRecord? current = _record;
    if (current == null) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    try {
      final bool blur = ref.read(blurPlateOnExportProvider);
      final ExportedCapture exported = await ref.read(exportServiceProvider).exportSingle(current, blurPlate: blur);
      await Share.shareXFiles(<XFile>[XFile(exported.jsonPath), XFile(exported.photoPath)]);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appExceptionMessage(l10n, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.detailTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final CaptureRecord? record = _record;
    if (record == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.detailTitle)),
        body: Center(child: Text(l10n.errorDatabaseUnavailable)),
      );
    }

    final String localeName = Localizations.localeOf(context).toString();
    final DateFormat dateFormat = DateFormat.yMMMMd(localeName);
    final DateFormat timeFormat = DateFormat.Hms(localeName);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.detailTitle),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: l10n.detailExport,
            onPressed: _export,
          ),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.file(File(record.imagePath), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _isEditing
                    ? TextField(
                        controller: _plateController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(border: const OutlineInputBorder(), labelText: l10n.detailCorrectedPlate),
                      )
                    : Text(record.displayPlate, style: Theme.of(context).textTheme.headlineSmall),
              ),
              const SizedBox(width: 8),
              CountryBadge(country: record.countryCode),
            ],
          ),
          if (!_isEditing && record.wasManuallyCorrected)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${l10n.validationDetectedPlate}: ${record.detectedPlate}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const Divider(height: 32),
          _InfoRow(label: l10n.validationCountry, value: countryDisplayName(l10n, record.countryCode)),
          _InfoRow(label: l10n.validationDate, value: dateFormat.format(record.capturedAt)),
          _InfoRow(label: l10n.validationTime, value: timeFormat.format(record.capturedAt)),
          if (record.hasLocation) ...<Widget>[
            _InfoRow(
              label: l10n.validationLocation,
              value: '${record.latitude!.toStringAsFixed(6)}, ${record.longitude!.toStringAsFixed(6)}',
            ),
            if (record.gpsAccuracy != null)
              _InfoRow(label: l10n.validationAccuracy, value: '±${record.gpsAccuracy!.toStringAsFixed(0)} m'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _openInMaps,
              icon: const Icon(Icons.map_outlined),
              label: Text(l10n.detailOpenMaps),
            ),
          ],
          const Divider(height: 32),
          Text(l10n.detailNote, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            enabled: _isEditing,
            maxLines: 3,
            decoration: InputDecoration(border: const OutlineInputBorder(), hintText: l10n.detailNoteHint),
          ),
          const SizedBox(height: 24),
          if (_isEditing)
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(l10n.detailSave),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            )
          else
            OutlinedButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
              label: Text(l10n.detailEdit),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Text('$label: ', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
