import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../providers/project_provider.dart';
import '../providers/settings_provider.dart';
import '../services/ics_exporter.dart';
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
    final json = context.read<ProjectProvider>().exportJson();
    await runGuarded(context, () async {
      Object? lastError;
      for (final f in await _backupCandidates()) {
        try {
          await f.writeAsString(json, flush: true);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Data diekspor ke ${f.path}')));
          }
          return;
        } catch (e) {
          lastError = e;
        }
      }
      throw lastError ?? 'Tidak ada lokasi penyimpanan yang bisa ditulis';
    });
  }

  Future<void> _exportIcs(BuildContext context) async {
    final projects = context.read<ProjectProvider>().all;
    final settings = context.read<SettingsProvider>().settings;
    if (projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Belum ada project untuk diekspor')));
      return;
    }
    await runGuarded(context, () async {
      // Alarm time mirrors the daily notification time so both reminders agree.
      final content = IcsExporter.build(
        projects,
        alarmHour: settings.notificationHour,
        alarmMinute: settings.notificationMinute,
      );
      final file = await IcsExporter.saveToDownloads(content);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kalender .ics diekspor ke ${file.path}')));
      }
    });
  }

  Future<void> _import(BuildContext context) async {
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
        title: const Text('Impor data'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(prefill.isEmpty
                  ? 'File cadangan tidak ditemukan. Tempel isi JSON di bawah.'
                  : 'File cadangan ditemukan. Pilih cara impor:'),
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(ctx).pop('merge'), child: const Text('Gabung')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop('replace'), child: const Text('Ganti semua')),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    final provider = context.read<ProjectProvider>();
    await runGuarded(context, () async {
      final n = await provider.importJson(ctrl.text, replace: choice == 'replace');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$n project berhasil diimpor')));
      }
    });
  }

  Future<void> _reset(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset semua data?'),
        content: const Text('Semua project, catatan, dan sub-tugas akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Reset')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final provider = context.read<ProjectProvider>();
    await runGuarded(context, () async {
      await provider.resetAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Semua data dihapus')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final s = sp.settings;
    final time = TimeOfDay(hour: s.notificationHour, minute: s.notificationMinute);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Tampilan'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, label: Text('Terang')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Gelap')),
                ButtonSegment(value: ThemeMode.system, label: Text('Sistem')),
              ],
              selected: {s.themeMode},
              onSelectionChanged: (v) => sp.update(s.copyWith(themeMode: v.first)),
            ),
          ),
          ListTile(
            title: const Text('Font'),
            subtitle: sp.customFontAvailable
                ? null
                : const Text('File font kustom tidak ditemukan, memakai cadangan'),
            trailing: DropdownButton<String>(
              value: s.fontFamily,
              items: const [
                DropdownMenuItem(value: AppSettings.fontCustom, child: Text('Kustom (TTF)')),
                DropdownMenuItem(value: AppSettings.fontPixel, child: Text('PressStart2P')),
                DropdownMenuItem(value: AppSettings.fontSystem, child: Text('Bawaan')),
              ],
              onChanged: (v) {
                if (v != null) sp.update(s.copyWith(fontFamily: v));
              },
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Notifikasi harian'),
            value: s.notificationsEnabled,
            onChanged: (v) async {
              await sp.update(s.copyWith(notificationsEnabled: v), reschedule: true);
            },
          ),
          ListTile(
            title: const Text('Jam notifikasi'),
            subtitle: Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: time,
                cancelText: 'Batal',
                confirmText: 'Pilih',
                helpText: 'Pilih jam notifikasi',
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
            title: const Text('Kutipan motivasi'),
            value: s.motivationEnabled,
            onChanged: (v) => sp.update(s.copyWith(motivationEnabled: v)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: const Text('Kelola tag'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const TagsScreen())),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Ekspor ke kalender (.ics)'),
            subtitle: const Text('Semua project, termasuk arsip'),
            onTap: () => _exportIcs(context),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Ekspor data (JSON)'),
            onTap: () => _export(context),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Impor data (JSON)'),
            onTap: () => _import(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset semua data'),
            onTap: () => _reset(context),
          ),
        ],
      ),
    );
  }
}
