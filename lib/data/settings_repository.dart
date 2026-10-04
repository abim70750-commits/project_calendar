import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsRepository {
  Future<AppSettings> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      // reload() so the alarm isolate sees values written by the UI isolate.
      await p.reload();
      const d = AppSettings();
      final modeName = p.getString('themeMode') ?? 'dark';
      return AppSettings(
        themeMode: ThemeMode.values.firstWhere((m) => m.name == modeName,
            orElse: () => ThemeMode.dark),
        fontFamily: p.getString('fontFamily') ?? d.fontFamily,
        notificationHour: p.getInt('notificationHour') ?? d.notificationHour,
        notificationMinute:
            p.getInt('notificationMinute') ?? d.notificationMinute,
        notificationsEnabled:
            p.getBool('notificationsEnabled') ?? d.notificationsEnabled,
        motivationEnabled: p.getBool('motivationEnabled') ?? d.motivationEnabled,
      );
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings s) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('themeMode', s.themeMode.name);
    await p.setString('fontFamily', s.fontFamily);
    await p.setInt('notificationHour', s.notificationHour);
    await p.setInt('notificationMinute', s.notificationMinute);
    await p.setBool('notificationsEnabled', s.notificationsEnabled);
    await p.setBool('motivationEnabled', s.motivationEnabled);
  }
}
