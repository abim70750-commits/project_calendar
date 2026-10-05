import 'package:flutter/material.dart';

/// User preferences persisted in shared_preferences.
class AppSettings {
  static const String fontCustom = 'MinecraftCustom';
  static const String fontPixel = 'PressStart2P';
  static const String fontSystem = 'system';

  final ThemeMode themeMode;
  final String fontFamily;
  final int notificationHour;
  final int notificationMinute;
  final bool notificationsEnabled;
  final bool motivationEnabled;

  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.fontFamily = fontCustom,
    this.notificationHour = 6,
    this.notificationMinute = 0,
    this.notificationsEnabled = true,
    this.motivationEnabled = true,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? fontFamily,
    int? notificationHour,
    int? notificationMinute,
    bool? notificationsEnabled,
    bool? motivationEnabled,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        fontFamily: fontFamily ?? this.fontFamily,
        notificationHour: notificationHour ?? this.notificationHour,
        notificationMinute: notificationMinute ?? this.notificationMinute,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        motivationEnabled: motivationEnabled ?? this.motivationEnabled,
      );
}
