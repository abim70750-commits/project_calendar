import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'models/app_settings.dart';
import 'providers/project_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/tag_provider.dart';
import 'screens/calendar_screen.dart';
import 'services/alarm_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

class ProjectCalendarApp extends StatefulWidget {
  const ProjectCalendarApp({super.key});

  @override
  State<ProjectCalendarApp> createState() => _ProjectCalendarAppState();
}

class _ProjectCalendarAppState extends State<ProjectCalendarApp> {
  @override
  void initState() {
    super.initState();
    // After the first frame so the permission dialog has an Activity to attach to.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final projects = context.read<ProjectProvider>();
      final tags = context.read<TagProvider>();
      final settings = context.read<SettingsProvider>().settings;
      // Tags first so projects load with their tag links already resolvable.
      await tags.load();
      await projects.load();
      await NotificationService.requestPermission();
      await AlarmService.schedule(settings);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SettingsProvider>();
    final s = sp.settings;
    return MaterialApp(
      // Resolved per locale so the OS app switcher shows the translated name.
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
      debugShowCheckedModeBanner: false,
      themeMode: s.themeMode,
      theme: buildTheme(Brightness.light, s.fontFamily, sp.fontAvailable(s.fontFamily)),
      darkTheme: buildTheme(Brightness.dark, s.fontFamily, sp.fontAvailable(s.fontFamily)),
      // Locales without translations fall back to English through supportedLocales.
      locale: AppLanguage.toLocale(s.languageCode),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const CalendarScreen(),
    );
  }
}
