import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/project_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/project.dart' show Project;
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

  /// The alarm isolate has no BuildContext, so strings are looked up by locale.
  /// Languages without translations yet resolve to English.
  static AppLocalizations _l10n(AppSettings s) {
    final locale = AppLanguage.toLocale(s.languageCode);
    final supported = AppLocalizations.delegate.isSupported(locale);
    return lookupAppLocalizations(supported ? locale : const Locale('en'));
  }

  static Future<void> _show(
      AppLocalizations l10n, int id, String title, String body) {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'project_reminders',
        l10n.notificationChannelName,
        channelDescription: l10n.notificationChannelDescription,
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
      100 + ((p.id.hashCode & 0x07FFFFFF) * 4) + slot;

  /// Called by the daily alarm: the summary plus each project's custom
  /// reminders. Doing per-project reminders here (same hour) avoids a timezone package.
  static Future<void> fireDaily(ProjectRepository repo, AppSettings s) async {
    final l10n = _l10n(s);
    final today = dateOnly(DateTime.now());
    final all = await repo.getAll();
    // Archived or finished projects never nag.
    final live = all.where((p) => !p.isCompleted && !p.isArchived).toList();

    final active = live
        .where((p) =>
            !dateOnly(p.startDate).isAfter(today) &&
            !dateOnly(p.deadline).isBefore(today))
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    if (active.isNotEmpty) {
      final lines = active
          .map((p) => l10n.notificationSummaryLine(p.name, daysLeftFor(p.deadline)))
          .join('\n');
      final body = s.motivationEnabled
          ? '$lines\n\n${MotivationQuotes.random(s.languageCode)}'
          : lines;
      await _show(l10n, _summaryId, l10n.notificationSummaryTitle(active.length), body);
    }

    for (final p in live) {
      final left = daysLeftFor(p.deadline);
      // The list index doubles as the notification slot, so max 3 ids per project.
      final slot = p.reminderDays.indexOf(left);
      if (slot < 0) continue;
      final id = _projectId(p, slot);
      if (left == 0) {
        await _show(l10n, id, l10n.notificationTodayTitle(p.name),
            l10n.notificationTodayBody);
      } else if (left == 1) {
        await _show(l10n, id, l10n.notificationTomorrowTitle(p.name),
            l10n.notificationTomorrowBody);
      } else {
        await _show(l10n, id, l10n.notificationSoonTitle(left, p.name),
            l10n.notificationSoonBody);
      }
    }
  }
}
