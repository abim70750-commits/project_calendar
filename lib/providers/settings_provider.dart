import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/settings_repository.dart';
import '../models/app_settings.dart';
import '../services/alarm_service.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repo = SettingsRepository();

  AppSettings settings = const AppSettings();

  /// Bundled font ids whose asset really loaded. A missing or empty TTF is
  /// simply absent here, and the theme falls back instead of crashing.
  final Set<String> _availableFonts = {};

  bool fontAvailable(String id) {
    final font = AppFont.byId(id);
    // Fonts without an asset (PressStart2P, system) are always "available".
    return font.asset == null || _availableFonts.contains(font.id);
  }

  Locale get locale => AppLanguage.toLocale(settings.languageCode);

  Future<void> init() async {
    settings = await _repo.load();
    for (final font in AppFont.all) {
      final asset = font.asset;
      if (asset == null) continue;
      try {
        final data = await rootBundle.load(asset);
        if (data.lengthInBytes > 0) _availableFonts.add(font.id);
      } catch (_) {
        // Missing asset: leave it out of the available set.
      }
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
