import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/settings_repository.dart';
import '../models/app_settings.dart';
import '../services/alarm_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repo = SettingsRepository();

  AppSettings settings = const AppSettings();

  /// False when the bundled TTF is missing or empty; the theme then falls back.
  bool customFontAvailable = false;

  Future<void> init() async {
    settings = await _repo.load();
    try {
      final data = await rootBundle.load('assets/fonts/minecraft.ttf');
      customFontAvailable = data.lengthInBytes > 0;
    } catch (_) {
      customFontAvailable = false;
    }
    notifyListeners();
  }

  Future<void> update(AppSettings next, {bool reschedule = false}) async {
    settings = next;
    notifyListeners();
    try {
      await _repo.save(next);
      if (reschedule) await AlarmService.schedule(next);
    } catch (e) {
      debugPrint('Saving settings failed: $e');
    }
  }
}
