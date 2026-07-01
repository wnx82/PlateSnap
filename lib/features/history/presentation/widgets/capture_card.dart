import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/entities/capture_record.dart';
import '../../../../presentation/widgets/country_badge.dart';

/// One row of the history list: thumbnail, plate, country badge, date/time
/// and coordinates.
class CaptureCard extends StatelessWidget {
  const CaptureCard({super.key, required this.record, required this.onTap, required this.onDelete});

  final CaptureRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final String localeName = Localizations.localeOf(context).toString();
    final DateFormat dateTimeFormat = DateFormat.yMMMd(localeName).add_Hm();
    final String? thumb = record.thumbnailPath;

    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 56,
            height: 56,
            child: thumb != null && File(thumb).existsSync()
                ? Image.file(File(thumb), fit: BoxFit.cover)
                : Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.directions_car),
                  ),
          ),
        ),
        title: Row(
          children: <Widget>[
            Text(record.displayPlate, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            CountryBadge(country: record.countryCode),
          ],
        ),
        subtitle: Text(
          record.hasLocation
              ? '${dateTimeFormat.format(record.capturedAt)} · ${record.latitude!.toStringAsFixed(4)}, ${record.longitude!.toStringAsFixed(4)}'
              : dateTimeFormat.format(record.capturedAt),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
