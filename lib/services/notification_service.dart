import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/project_repository.dart';
import '../models/app_settings.dart';
import '../models/project.dart';
import '../utils/date_utils.dart';
import '../utils/motivation_quotes.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _summaryId = 1;

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
  }

  /// Android 13+ requires a runtime grant; older versions report granted.
  static Future<void> requestPermission() async {
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted) await Permission.notification.request();
    } catch (e) {
      debugPrint('Notification permission error: $e');
    }
  }

  static Future<void> _show(int id, String title, String body) {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'project_reminders',
        'Pengingat Project',
        channelDescription: 'Pengingat harian dan deadline project',
        importance: Importance.high,
        priority: Priority.high,
        // Big text so every project line is visible without expanding blindly.
        styleInformation: BigTextStyleInformation(body),
      ),
    );
    return _plugin.show(id, title, body, details);
  }

  // Stable per-project ids so a repeat notification replaces the old one.
  static int _projectId(Project p, int slot) =>
      100 + ((p.id.hashCode & 0x0FFFFFFF) * 2) + slot;

  /// Called by the daily alarm: summary + H-1 + day-H deadline reminders.
  /// Doing per-project reminders here (same hour) avoids a timezone package.
  static Future<void> fireDaily(ProjectRepository repo, AppSettings s) async {
    final today = dateOnly(DateTime.now());
    final all = await repo.getAll();
    final active = all
        .where((p) =>
            !p.isCompleted &&
            !dateOnly(p.startDate).isAfter(today) &&
            !dateOnly(p.deadline).isBefore(today))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    if (active.isNotEmpty) {
      final lines = active
          .map((p) => '${p.name} — tinggal ${daysLeftFor(p.deadline)} hari lagi')
          .join('\n');
      final body =
          s.motivationEnabled ? '$lines\n\n${MotivationQuotes.random()}' : lines;
      await _show(_summaryId, 'Woy lu ada ${active.length} project nih', body);
    }

    for (final p in active) {
      final left = daysLeftFor(p.deadline);
      if (left == 1) {
        await _show(_projectId(p, 0), 'Deadline besok: ${p.name}',
            'Tinggal 1 hari lagi. Gas selesaikan!');
      } else if (left == 0) {
        await _show(_projectId(p, 1), 'Hari ini deadline: ${p.name}',
            'Countdown 24 jam. Kalau ga kelar, project jadi ngarett.');
      }
    }
  }
}
