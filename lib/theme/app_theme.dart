import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_settings.dart';

/// Glyphs missing from the selected font (CJK, Arabic, Devanagari, Thai, ...) are
/// drawn with these system families instead of showing empty boxes. Families that a
/// device does not have are skipped, and Android also falls back on its own.
const List<String> kFontFamilyFallback = [
  'NotoSans',
  'NotoSansCJK',
  'NotoSansArabic',
  'NotoSansDevanagari',
  'NotoSansThai',
  'Roboto',
  'sans-serif',
];

/// Font chain: bundled TTF -> PressStart2P (google_fonts) -> system default, each
/// followed by [kFontFamilyFallback]. Every branch is guarded so a font problem
/// can never crash startup.
ThemeData buildTheme(Brightness brightness, String fontId, bool fontAvailable) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorSchemeSeed: const Color(0xFF43A047),
  );

  final font = AppFont.byId(fontId);
  var family = font.id;
  if (font.asset != null && !fontAvailable) family = AppFont.pixel;

  TextTheme withFallback(TextTheme t, {String? fontFamily}) =>
      t.apply(fontFamily: fontFamily, fontFamilyFallback: kFontFamilyFallback);

  try {
    if (family == AppFont.pixel) {
      return base.copyWith(
        textTheme: withFallback(GoogleFonts.pressStart2pTextTheme(base.textTheme)),
        primaryTextTheme:
            withFallback(GoogleFonts.pressStart2pTextTheme(base.primaryTextTheme)),
      );
    }
    // "system" keeps the platform family but still gets the fallback chain.
    final fontFamily = family == AppFont.system ? null : family;
    return base.copyWith(
      textTheme: withFallback(base.textTheme, fontFamily: fontFamily),
      primaryTextTheme: withFallback(base.primaryTextTheme, fontFamily: fontFamily),
    );
  } catch (_) {
    // Fall through to the unmodified theme.
  }
  return base;
}
