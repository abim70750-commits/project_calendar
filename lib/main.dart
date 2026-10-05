import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/project_repository.dart';
import 'data/tag_repository.dart';
import 'providers/project_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/tag_provider.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Each init is isolated: a failing plugin must not prevent the UI from launching.
  Future<void> safe(Future<void> Function() f, String label) async {
    try {
      await f();
    } catch (e) {
      debugPrint('Startup step "$label" failed: $e');
    }
  }

  await safe(() => initializeDateFormatting('id_ID'), 'date formatting');
  await safe(AndroidAlarmManager.initialize, 'alarm manager');
  await safe(NotificationService.init, 'notifications');

  final settings = SettingsProvider();
  await safe(settings.init, 'settings');
  final projects = ProjectProvider(ProjectRepository());
  // Tag edits change what projects embed, so tags tell the project list to re-read.
  final tags = TagProvider(TagRepository(), onChanged: projects.refresh);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<ProjectProvider>.value(value: projects),
        ChangeNotifierProvider<TagProvider>.value(value: tags),
      ],
      child: const ProjectCalendarApp(),
    ),
  );
}
