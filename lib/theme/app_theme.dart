import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_settings.dart';

/// Fallback chain: bundled TTF -> PressStart2P (google_fonts) -> system default.
/// Every branch is guarded so a font problem can never crash startup.
ThemeData buildTheme(Brightness brightness, String fontId, bool fontAvailable) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorSchemeSeed: const Color(0xFF43A047),
  );

  final font = AppFont.byId(fontId);
  var family = font.id;
  if (font.asset != null && !fontAvailable) family = AppFont.pixel;

  try {
    if (family == AppFont.system) return base;
    if (family == AppFont.pixel) {
      return base.copyWith(
        textTheme: GoogleFonts.pressStart2pTextTheme(base.textTheme),
        primaryTextTheme: GoogleFonts.pressStart2pTextTheme(base.primaryTextTheme),
      );
    }
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: family),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: family),
    );
  } catch (_) {
    // Fall through to the system font.
  }
  return base;
}
