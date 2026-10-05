import 'dart:ui';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';

import '../data/project_repository.dart';
import '../data/settings_repository.dart';
import '../models/app_settings.dart';
import 'notification_service.dart';
import 'overdue_checker.dart';

const int _dailyAlarmId = 7001;

/// Runs in a background isolate, possibly with the app fully closed.
/// It must be top-level and annotated or release builds tree-shake it.
@pragma('vm:entry-point')
Future<void> dailyAlarmCallback() async {
  DartPluginRegistrant.ensureInitialized();
  AppSettings settings = const AppSettings();
  try {
    settings = await SettingsRepository().load();
    final repo = ProjectRepository();
    await OverdueChecker.run(repo);
    if (settings.notificationsEnabled) {
      await NotificationService.init();
      await NotificationService.fireDaily(repo, settings);
    }
  } catch (e) {
    debugPrint('Daily alarm failed: $e');
  } finally {
    // Always chain the next day, even after a failure, or reminders die silently.
    await AlarmService.schedule(settings);
  }
}

class AlarmService {
  static DateTime nextFire(AppSettings s, [DateTime? from]) {
    final now = from ?? DateTime.now();
    var t = DateTime(now.year, now.month, now.day, s.notificationHour,
        s.notificationMinute);
    if (!t.isAfter(now.add(const Duration(seconds: 5)))) {
      t = DateTime(now.year, now.month, now.day + 1, s.notificationHour,
          s.notificationMinute);
    }
    return t;
  }

  /// Replaces any existing alarm with the same id, so calling it repeatedly is safe.
  static Future<void> schedule(AppSettings s) async {
    try {
      await AndroidAlarmManager.oneShotAt(
        nextFire(s),
        _dailyAlarmId,
        dailyAlarmCallback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
    } catch (e) {
      debugPrint('Alarm scheduling failed: $e');
    }
  }
}
