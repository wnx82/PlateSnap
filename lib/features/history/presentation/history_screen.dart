import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/utils/country_label.dart';
import '../../../core/utils/error_messages.dart';
import '../../../domain/entities/capture_record.dart';
import '../../../domain/repositories/capture_repository.dart';
import '../../../presentation/providers/repository_providers.dart';
import '../../../presentation/widgets/confirm_dialog.dart';
import '../../capture_detail/presentation/capture_detail_screen.dart';
import 'widgets/capture_card.dart';

/// Searchable, filterable list of every locally stored capture, most recent
/// first.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  PlateCountry? _countryFilter;
  DateTime? _dateFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  CaptureQuery get _query => CaptureQuery(
        searchText: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        country: _countryFilter,
        fromDate: _dateFilter == null ? null : DateTime(_dateFilter!.year, _dateFilter!.month, _dateFilter!.day),
        toDate: _dateFilter == null
            ? null
            : DateTime(_dateFilter!.year, _dateFilter!.month, _dateFilter!.day, 23, 59, 59),
      );

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateFilter ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _dateFilter = picked);
    }
  }

  Future<void> _confirmDelete(BuildContext context, AppLocalizations l10n, String id) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: l10n.historyDeleteConfirmTitle,
      message: l10n.historyDeleteConfirmMessage,
      confirmLabel: l10n.actionDelete,
      cancelLabel: l10n.actionCancel,
    );
    if (!confirmed) return;
    try {
      await ref.read(captureRepositoryProvider).delete(id);
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appExceptionMessage(l10n, e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyTitle)),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.historySearchHint,
                border: const OutlineInputBorder(),
                isDense: true,
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(_searchController.clear),
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  _countryChip(l10n, null, l10n.historyFilterAll),
                  _countryChip(l10n, PlateCountry.be, countryDisplayName(l10n, PlateCountry.be)),
                  _countryChip(l10n, PlateCountry.fr, countryDisplayName(l10n, PlateCountry.fr)),
                  _countryChip(l10n, PlateCountry.unknown, countryDisplayName(l10n, PlateCountry.unknown)),
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.event, size: 18),
                    label: Text(
                      _dateFilter == null
                          ? l10n.historyFilterDate
                          : DateFormat.yMd(Localizations.localeOf(context).toString()).format(_dateFilter!),
                    ),
                    onPressed: _pickDate,
                  ),
                  if (_dateFilter != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _dateFilter = null),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CaptureRecord>>(
              stream: ref.watch(captureRepositoryProvider).watchAll(query: _query),
              builder: (BuildContext context, AsyncSnapshot<List<CaptureRecord>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text(l10n.errorDatabaseUnavailable));
                }
                final List<CaptureRecord> records = snapshot.data ?? const <CaptureRecord>[];
                if (records.isEmpty) {
                  return _EmptyState(l10n: l10n);
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: records.length,
                  itemBuilder: (BuildContext context, int index) {
                    final CaptureRecord record = records[index];
                    return CaptureCard(
                      record: record,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => CaptureDetailScreen(captureId: record.id)),
                      ),
                      onDelete: () => _confirmDelete(context, l10n, record.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _countryChip(AppLocalizations l10n, PlateCountry? country, String label) {
    final bool selected = _countryFilter == country;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _countryFilter = country),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.photo_library_outlined, size: 64),
            const SizedBox(height: 16),
            Text(l10n.historyEmptyTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              l10n.historyEmptySubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
