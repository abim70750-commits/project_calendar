import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../providers/project_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ics_exporter.dart';
import '../utils/constants.dart';
import 'tags_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String _fileName = 'project_calendar_backup.json';

  /// Public Downloads first; scoped storage on Android 11+ often refuses it,
  /// so the app-specific external folder is the guaranteed fallback.
  Future<List<File>> _backupCandidates() async {
    final files = <File>[File('/storage/emulated/0/Download/$_fileName')];
    try {
      final dir = await getExternalStorageDirectory();
      if (dir != null) files.add(File('${dir.path}/$_fileName'));
    } catch (_) {}
    final docs = await getApplicationDocumentsDirectory();
    files.add(File('${docs.path}/$_fileName'));
    return files;
  }

  Future<void> _export(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final json = context.read<ProjectProvider>().exportJson();
    await runGuarded(context, () async {
      Object? lastError;
      for (final f in await _backupCandidates()) {
        try {
          await f.writeAsString(json, flush: true);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.settingsExportJsonDone(f.path))));
          }
          return;
        } catch (e) {
          lastError = e;
        }
      }
      throw lastError ?? l10n.errorNoWritableLocation;
    });
  }

  Future<void> _exportIcs(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final projects = context.read<ProjectProvider>().all;
    final settings = context.read<SettingsProvider>().settings;
    if (projects.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.settingsExportIcsEmpty)));
      return;
    }
    await runGuarded(context, () async {
      // Alarm time mirrors the daily notification time so both reminders agree.
      final content = IcsExporter.build(
        projects,
        l10n: l10n,
        alarmHour: settings.notificationHour,
        alarmMinute: settings.notificationMinute,
      );
      final file = await IcsExporter.saveToDownloads(content,
          noLocationMessage: l10n.errorNoWritableLocation);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.settingsExportIcsDone(file.path))));
      }
    });
  }

  Future<void> _import(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    String prefill = '';
    for (final f in await _backupCandidates()) {
      try {
        if (await f.exists()) {
          prefill = await f.readAsString();
          break;
        }
      } catch (_) {}
    }
    if (!context.mounted) return;
    final ctrl = TextEditingController(text: prefill);
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsImportTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(prefill.isEmpty
                  ? l10n.settingsImportNotFound
                  : l10n.settingsImportFound),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                maxLines: 5,
                style: const TextStyle(fontSize: 11),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.commonCancel)),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop('merge'),
              child: Text(l10n.commonMerge)),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop('replace'),
              child: Text(l10n.commonReplaceAll)),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    final provider = context.read<ProjectProvider>();
    await runGuarded(context, () async {
      try {
        final n = await provider.importJson(ctrl.text, replace: choice == 'replace');
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.settingsImportDone(n))));
        }
      } on FormatException {
        // Bad JSON or the wrong structure: say so in plain words instead of a raw exception.
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.settingsImportInvalid)));
        }
      }
    });
  }

  Future<void> _reset(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsResetTitle),
        content: Text(l10n.settingsResetMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.commonReset)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final provider = context.read<ProjectProvider>();
    await runGuarded(context, () async {
      await provider.resetAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.settingsResetDone)));
      }
    });
  }

  void _showLicense(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.aboutLicenseName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(AppConstants.mitLicenseText,
                  style: const TextStyle(fontSize: 11)),
              const SizedBox(height: 12),
              SelectableText(l10n.aboutLicenseUrlLabel(AppConstants.licenseUrl),
                  style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.commonClose)),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sp = context.watch<SettingsProvider>();
    final s = sp.settings;
    final time = TimeOfDay(hour: s.notificationHour, minute: s.notificationMinute);
    final fontMissing = !sp.fontAvailable(s.fontFamily);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        children: [
          _sectionHeader(context, l10n.settingsAppearance),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.light, label: Text(l10n.themeLight)),
                ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark)),
                ButtonSegment(value: ThemeMode.system, label: Text(l10n.themeSystem)),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (v) => sp.update(s.copyWith(themeMode: v.first)),
            ),
          ),
          ListTile(
            title: Text(l10n.settingsFontLabel),
            subtitle: fontMissing ? Text(l10n.settingsFontMissing) : null,
            trailing: DropdownButton<String>(
              value: AppFont.byId(s.fontFamily).id,
              items: [
                for (final f in AppFont.all)
                  DropdownMenuItem(
                    value: f.id,
                    child: Text(f.label ?? l10n.fontSystemDefault),
                  ),
              ],
              onChanged: (v) {
                if (v != null) sp.update(s.copyWith(fontFamily: v));
              },
            ),
          ),
          ListTile(
            title: Text(l10n.settingsLanguageLabel),
            trailing: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: DropdownButton<String>(
                isExpanded: true,
                value: AppLanguage.all.any((l) => l.code == s.languageCode)
                    ? s.languageCode
                    : 'en',
                items: [
                  for (final lang in AppLanguage.all)
                    DropdownMenuItem(
                      value: lang.code,
                      child: Text(lang.nativeName, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) sp.update(s.copyWith(languageCode: v));
                },
              ),
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(l10n.settingsDailyNotifications),
            value: s.notificationsEnabled,
            onChanged: (v) async {
              await sp.update(s.copyWith(notificationsEnabled: v), reschedule: true);
            },
          ),
          ListTile(
            title: Text(l10n.settingsNotificationTime),
            subtitle: Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
                cancelText: l10n.commonCancel,
                confirmText: l10n.commonSelect,
                helpText: l10n.settingsPickTimeHelp,
              );
              if (picked != null) {
                await sp.update(
                  s.copyWith(
                      notificationHour: picked.hour, notificationMinute: picked.minute),
                  reschedule: true,
                );
              }
            },
          ),
          SwitchListTile(
            title: Text(l10n.settingsMotivation),
            value: s.motivationEnabled,
            onChanged: (v) => sp.update(s.copyWith(motivationEnabled: v)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: Text(l10n.settingsManageTags),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const TagsScreen())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.event),
            title: Text(l10n.settingsExportIcs),
            subtitle: Text(l10n.settingsExportIcsSubtitle),
            onTap: () => _exportIcs(context),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: Text(l10n.settingsExportJson),
            onTap: () => _export(context),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: Text(l10n.settingsImportJson),
            onTap: () => _import(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(l10n.settingsResetData),
            onTap: () => _reset(context),
          ),
          const Divider(),
          _sectionHeader(context, l10n.aboutSectionTitle),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.aboutAppName),
            subtitle: Text(l10n.appTitle),
          ),
          ListTile(
            leading: const Icon(Icons.tag),
            title: Text(l10n.aboutVersion),
            // Single source of truth: AppConstants, never a hardcoded literal.
            subtitle: const Text(AppConstants.appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.copyright),
            title: Text(l10n.aboutCopyright),
            subtitle: Text(l10n.aboutCopyrightValue(
                '${AppConstants.copyrightYear}', AppConstants.copyrightHolder)),
          ),
          ListTile(
            leading: const Icon(Icons.gavel),
            title: Text(l10n.aboutLicense),
            subtitle: Text(l10n.aboutLicenseName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLicense(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
