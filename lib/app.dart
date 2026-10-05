import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

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
      title: 'Project Calendar',
      debugShowCheckedModeBanner: false,
      themeMode: s.themeMode,
      theme: buildTheme(Brightness.light, s.fontFamily, sp.customFontAvailable),
      darkTheme: buildTheme(Brightness.dark, s.fontFamily, sp.customFontAvailable),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const CalendarScreen(),
    );
  }
}
