import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_settings.dart';

/// Fallback chain: custom TTF -> PressStart2P (google_fonts) -> system default.
/// Every branch is guarded so a font problem can never crash startup.
ThemeData buildTheme(Brightness brightness, String fontFamily, bool customAvailable) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorSchemeSeed: const Color(0xFF43A047),
  );

  var family = fontFamily;
  if (family == AppSettings.fontCustom && !customAvailable) {
    family = AppSettings.fontPixel;
  }

  try {
    if (family == AppSettings.fontCustom) {
      return base.copyWith(
        textTheme: base.textTheme.apply(fontFamily: AppSettings.fontCustom),
        primaryTextTheme:
            base.primaryTextTheme.apply(fontFamily: AppSettings.fontCustom),
      );
    }
    if (family == AppSettings.fontPixel) {
      return base.copyWith(
        textTheme: GoogleFonts.pressStart2pTextTheme(base.textTheme),
        primaryTextTheme: GoogleFonts.pressStart2pTextTheme(base.primaryTextTheme),
      );
    }
  } catch (_) {
    // Fall through to the system font.
  }
  return base;
}
