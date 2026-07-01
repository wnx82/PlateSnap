import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/utils/error_messages.dart';
import '../../../domain/entities/capture_record.dart';
import '../../../presentation/providers/repository_providers.dart';
import '../../../presentation/providers/settings_providers.dart';
import '../../../presentation/widgets/confirm_dialog.dart';

/// Language, theme, privacy toggles, data export and the privacy page —
/// everything that affects the app globally rather than a single capture.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final Locale? locale = ref.watch(localeProvider);
    final bool blurOnExport = ref.watch(blurPlateOnExportProvider);
    final bool keepOriginal = ref.watch(keepOriginalPhotoProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: <Widget>[
          _SectionHeader(title: l10n.settingsLanguage),
          RadioGroup<Locale?>(
            groupValue: locale,
            onChanged: (Locale? v) => ref.read(localeProvider.notifier).setLocale(v),
            child: const Column(
              children: <Widget>[
                RadioListTile<Locale?>(title: Text('Système / System'), value: null),
                RadioListTile<Locale?>(title: Text('Français'), value: Locale('fr')),
                RadioListTile<Locale?>(title: Text('English'), value: Locale('en')),
                RadioListTile<Locale?>(title: Text('Nederlands'), value: Locale('nl')),
              ],
            ),
          ),
          const Divider(),
          _SectionHeader(title: l10n.settingsTheme),
          RadioGroup<ThemeMode>(
            groupValue: themeMode,
            onChanged: (ThemeMode? v) => ref.read(themeModeProvider.notifier).setThemeMode(v ?? ThemeMode.system),
            child: Column(
              children: <Widget>[
                RadioListTile<ThemeMode>(title: Text(l10n.settingsThemeSystem), value: ThemeMode.system),
                RadioListTile<ThemeMode>(title: Text(l10n.settingsThemeLight), value: ThemeMode.light),
                RadioListTile<ThemeMode>(title: Text(l10n.settingsThemeDark), value: ThemeMode.dark),
              ],
            ),
          ),
          const Divider(),
          _SectionHeader(title: l10n.privacyTitle),
          SwitchListTile(
            title: Text(l10n.settingsBlurPlateExport),
            value: blurOnExport,
            onChanged: (bool v) => ref.read(blurPlateOnExportProvider.notifier).setValue(v),
          ),
          SwitchListTile(
            title: Text(l10n.settingsKeepOriginalPhoto),
            value: keepOriginal,
            onChanged: (bool v) => ref.read(keepOriginalPhotoProvider.notifier).setValue(v),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.settingsPrivacyPage),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/privacy'),
          ),
          const Divider(),
          _SectionHeader(title: '${l10n.settingsExportCsv} / ${l10n.settingsExportJson}'),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: Text(l10n.settingsExportCsv),
            onTap: () => _exportAll(context, ref, csv: true),
          ),
          ListTile(
            leading: const Icon(Icons.data_object_outlined),
            title: Text(l10n.settingsExportJson),
            onTap: () => _exportAll(context, ref, csv: false),
          ),
          const Divider(),
          ListTile(
            iconColor: Theme.of(context).colorScheme.error,
            textColor: Theme.of(context).colorScheme.error,
            leading: const Icon(Icons.delete_forever_outlined),
            title: Text(l10n.settingsDeleteAllHistory),
            onTap: () => _deleteAll(context, ref, l10n),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAll(BuildContext context, WidgetRef ref, {required bool csv}) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    try {
      final List<CaptureRecord> records = await ref.read(captureRepositoryProvider).getAll();
      final String path = csv
          ? await ref.read(exportServiceProvider).exportToCsv(records)
          : await ref.read(exportServiceProvider).exportToJson(records);
      await Share.shareXFiles(<XFile>[XFile(path)]);
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appExceptionMessage(l10n, e))));
      }
    }
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final bool confirmed = await showConfirmDialog(
      context,
      title: l10n.settingsDeleteAllConfirmTitle,
      message: l10n.settingsDeleteAllConfirmMessage,
      confirmLabel: l10n.actionDelete,
      cancelLabel: l10n.actionCancel,
    );
    if (!confirmed) return;
    try {
      await ref.read(privacyServiceProvider).deleteAllData();
    } on AppException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(appExceptionMessage(l10n, e))));
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
