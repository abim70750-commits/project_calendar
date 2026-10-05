import 'dart:math';

/// Quotes keyed by language code so more languages can be added without touching callers.
class MotivationQuotes {
  static const Map<String, List<String>> byLanguage = {
    'en': [
      'Start now. Perfect comes later.',
      'One small step today beats a big plan tomorrow.',
      'Deadlines are friends, not enemies.',
      "Don't wait for motivation. Build discipline.",
      'Small progress is still progress.',
      'Focus. Work. Finish.',
      'You run today. Not laziness.',
      'Tired is okay. Quitting is not.',
      "What you delay today becomes tomorrow's weight.",
      'Do it now. Relax later.',
      'You are stronger than your excuses.',
      'Done beats perfect.',
      'Check off one thing today.',
      'Consistency beats motivation.',
      'Big goals start with small tasks.',
      "Don't compare your start to someone's finish.",
      'Time keeps moving. Move with it.',
      'Work hard today, be proud tomorrow.',
      'Break big problems into small steps.',
      'Failure is data, not the end.',
      'Begin now, not later.',
      'One focused hour beats a lazy day.',
      "You've survived harder days.",
      'Discipline is self-respect.',
      "Don't let the deadline chase you.",
      'Finish one thing and feel the relief.',
      'A plan without action is just a wish.',
      "Slow is fine, as long as it's finished.",
      'Today is yours. Use it well.',
      'Project done, mind at ease.',
    ],
  };

  static final Random _rng = Random();

  /// Unknown or untranslated languages fall back to English.
  static List<String> forLanguage(String? code) {
    final base = code?.split('-').first;
    return byLanguage[code] ?? byLanguage[base] ?? byLanguage['en']!;
  }

  static String random([String? languageCode]) {
    final list = forLanguage(languageCode);
    return list[_rng.nextInt(list.length)];
  }
}
