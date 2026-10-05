import 'package:flutter/material.dart';

/// One selectable UI font. [asset] is null for fonts that are not bundled
/// (PressStart2P comes from google_fonts, "system" is the platform default).
class AppFont {
  const AppFont(this.id, this.label, {this.asset});

  final String id;

  /// Proper font name, not translated. Null means "system default" (localized in the UI).
  final String? label;
  final String? asset;

  static const String minecraft = 'MinecraftCustom';
  static const String pixel = 'PressStart2P';
  static const String system = 'system';

  static const List<AppFont> all = [
    AppFont(minecraft, 'Minecraft', asset: 'assets/fonts/minecraft.ttf'),
    AppFont('Minecraftia', 'Minecraftia', asset: 'assets/fonts/minecraftia.ttf'),
    AppFont('JMHTypewriter', 'JMH Typewriter',
        asset: 'assets/fonts/jmh_typewriter_regular.ttf'),
    AppFont('MangaTemple', 'Manga Temple', asset: 'assets/fonts/manga_temple.ttf'),
    AppFont('ArastinPro', 'Arastin Pro', asset: 'assets/fonts/arastin_pro.ttf'),
    AppFont(pixel, 'PressStart2P'),
    AppFont(system, null),
  ];

  static AppFont byId(String id) =>
      all.firstWhere((f) => f.id == id, orElse: () => all.first);
}

/// A language the user can pick. Names are endonyms and are intentionally not translated.
class AppLanguage {
  const AppLanguage(this.code, this.nativeName);

  /// Stored in shared_preferences. "zh-Hans" / "pt-BR" style codes carry script or country.
  final String code;
  final String nativeName;

  static const List<AppLanguage> all = [
    AppLanguage('en', 'English (US)'),
    AppLanguage('id', 'Bahasa Indonesia'),
    AppLanguage('zh-Hans', '中文 (简体)'),
    AppLanguage('zh-Hant', '中文 (繁體)'),
    AppLanguage('ja', '日本語'),
    AppLanguage('ko', '한국어'),
    AppLanguage('es', 'Español'),
    AppLanguage('pt-BR', 'Português (Brasil)'),
    AppLanguage('de', 'Deutsch'),
    AppLanguage('fr', 'Français'),
    AppLanguage('ar', 'العربية'),
    AppLanguage('hi', 'हिन्दी'),
    AppLanguage('th', 'ไทย'),
    AppLanguage('vi', 'Tiếng Việt'),
    AppLanguage('fil', 'Tagalog'),
    AppLanguage('ru', 'Русский'),
    AppLanguage('it', 'Italiano'),
    AppLanguage('tr', 'Türkçe'),
  ];

  /// Turns a stored code into a Locale. Null or unknown input means English.
  static Locale toLocale(String? code) {
    if (code == null || code.isEmpty) return const Locale('en');
    final parts = code.split('-');
    if (parts.length == 1) return Locale(parts[0]);
    // A 4-letter subtag is a script (Hans/Hant); otherwise it is a country (BR).
    return parts[1].length == 4
        ? Locale.fromSubtags(languageCode: parts[0], scriptCode: parts[1])
        : Locale(parts[0], parts[1]);
  }
}

/// User preferences persisted in shared_preferences.
class AppSettings {
  // Kept so existing code and stored values keep working.
  static const String fontCustom = AppFont.minecraft;
  static const String fontPixel = AppFont.pixel;
  static const String fontSystem = AppFont.system;

  final ThemeMode themeMode;
  final String fontFamily;
  final int notificationHour;
  final int notificationMinute;
  final bool notificationsEnabled;
  final bool motivationEnabled;

  /// Null means "never chosen": the app uses English.
  final String? languageCode;

  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.fontFamily = fontCustom,
    this.notificationHour = 6,
    this.notificationMinute = 0,
    this.notificationsEnabled = true,
    this.motivationEnabled = true,
    this.languageCode,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? fontFamily,
    int? notificationHour,
    int? notificationMinute,
    bool? notificationsEnabled,
    bool? motivationEnabled,
    String? languageCode,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        fontFamily: fontFamily ?? this.fontFamily,
        notificationHour: notificationHour ?? this.notificationHour,
        notificationMinute: notificationMinute ?? this.notificationMinute,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        motivationEnabled: motivationEnabled ?? this.motivationEnabled,
        languageCode: languageCode ?? this.languageCode,
      );
}
