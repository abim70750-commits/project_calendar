import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/project.dart';

/// Builds an RFC 5545 calendar with one all-day VEVENT per project.
class IcsExporter {
  static String build(
    List<Project> projects, {
    int alarmHour = 6,
    int alarmMinute = 0,
    DateTime? now,
  }) {
    final stamp = _utc(now ?? DateTime.now());
    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Project Calendar//ID',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'X-WR-CALNAME:Project Calendar',
    ];

    for (final p in projects) {
      // DTEND of an all-day event is exclusive, so the deadline day needs +1.
      final endExclusive =
          DateTime(p.deadline.year, p.deadline.month, p.deadline.day + 1);
      final desc = StringBuffer()
        ..write('Progres: ${p.progress}%')
        ..write('\nPrioritas: ${p.priority.label}')
        ..write('\nStatus: ${p.isCompleted ? 'Selesai' : (p.isOverdue ? 'Overdue' : 'Berjalan')}');
      if (p.tags.isNotEmpty) {
        desc.write('\nTag: ${p.tags.map((t) => t.name).join(', ')}');
      }
      if (p.subtasks.isNotEmpty) {
        final done = p.subtasks.where((s) => s.isDone).length;
        desc.write('\nSub-tugas: $done/${p.subtasks.length}');
      }
      if (p.notes.trim().isNotEmpty) desc.write('\n\n${p.notes.trim()}');

      lines
        ..add('BEGIN:VEVENT')
        ..add('UID:${p.id}@projectcalendar.app')
        ..add('DTSTAMP:$stamp')
        ..add('DTSTART;VALUE=DATE:${_date(p.startDate)}')
        ..add('DTEND;VALUE=DATE:${_date(endExclusive)}')
        ..add('SUMMARY:${_escape(p.name)}')
        ..add('DESCRIPTION:${_escape(desc.toString())}')
        ..add('PRIORITY:${_icsPriority(p.priority)}')
        ..add('STATUS:CONFIRMED')
        ..add('TRANSP:TRANSPARENT');
      if (p.tags.isNotEmpty) {
        lines.add('CATEGORIES:${p.tags.map((t) => _escape(t.name)).join(',')}');
      }

      if (!p.isCompleted) {
        for (final days in p.reminderDays) {
          // TRIGGER is measured back from the event END (deadline day + 1, 00:00),
          // so the alarm lands on (deadline - days) at the daily notification time.
          final minutes =
              days * 1440 + 1440 - (alarmHour * 60 + alarmMinute);
          if (minutes <= 0) continue;
          lines
            ..add('BEGIN:VALARM')
            ..add('ACTION:DISPLAY')
            ..add('DESCRIPTION:${_escape('${reminderLabel(days)}: ${p.name}')}')
            ..add('TRIGGER;RELATED=END:-PT${minutes}M')
            ..add('END:VALARM');
        }
      }
      lines.add('END:VEVENT');
    }

    lines.add('END:VCALENDAR');
    return '${lines.expand(_fold).join('\r\n')}\r\n';
  }

  /// Writes to public Downloads; falls back to app storage because scoped
  /// storage on Android 11+ often rejects direct writes there.
  static Future<File> saveToDownloads(String content, {DateTime? now}) async {
    final n = now ?? DateTime.now();
    final name = 'project_calendar_${_date(n)}.ics';
    final candidates = <File>[File('/storage/emulated/0/Download/$name')];
    try {
      final ext = await getExternalStorageDirectory();
      if (ext != null) candidates.add(File('${ext.path}/$name'));
    } catch (_) {}
    final docs = await getApplicationDocumentsDirectory();
    candidates.add(File('${docs.path}/$name'));

    Object? lastError;
    for (final f in candidates) {
      try {
        await f.writeAsString(content, flush: true);
        return f;
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? 'Tidak ada lokasi penyimpanan yang bisa ditulis';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _date(DateTime d) => '${d.year.toString().padLeft(4, '0')}${_two(d.month)}${_two(d.day)}';

  static String _utc(DateTime d) {
    final u = d.toUtc();
    return '${_date(u)}T${_two(u.hour)}${_two(u.minute)}${_two(u.second)}Z';
  }

  static String _escape(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll(';', '\\;')
      .replaceAll(',', '\\,')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\n', '\\n');

  /// iCalendar PRIORITY: 1 = highest, 9 = lowest, 0 = undefined.
  static int _icsPriority(Priority p) {
    switch (p) {
      case Priority.high:
        return 1;
      case Priority.medium:
        return 5;
      case Priority.low:
        return 9;
      case Priority.none:
        return 0;
    }
  }

  /// RFC 5545 limits lines to 75 octets; continuation lines start with a space.
  /// Counting UTF-8 bytes (not characters) keeps Indonesian text with accents valid.
  static List<String> _fold(String line) {
    final out = <String>[];
    var buf = StringBuffer();
    var bytes = 0;
    for (final rune in line.runes) {
      final ch = String.fromCharCode(rune);
      final len = utf8.encode(ch).length;
      if (bytes + len > 75) {
        out.add(buf.toString());
        buf = StringBuffer(' ');
        bytes = 1;
      }
      buf.write(ch);
      bytes += len;
    }
    out.add(buf.toString());
    return out;
  }
}
