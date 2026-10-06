# Project Calendar

Calendar-based project management app with color-coded deadlines, notifications, and statistics.
Android only, built with Flutter (Material 3, dark theme by default).

## Features

- Month calendar with a colored dot per project (green / yellow / red / grey)
- Projects with start date, deadline, manual progress, markdown notes, and a reorderable subtask checklist
- Priority levels, colored tags (many-to-many), search, filters, and sorting
- Daily notification at a configurable time (works with the app closed), plus up to 3 custom reminders per project
- Overdue projects stay visible and turn permanently red until completed
- Archive (completed projects are archived after 7 days) and a statistics screen
- Export to `.ics` (calendar apps), JSON export/import, reset
- 18 interface languages

## Localization

The app is available in 18 languages: English (US), Bahasa Indonesia, Chinese (Simplified and
Traditional), Japanese, Korean, Spanish, Portuguese (Brazil), German, French, Arabic, Hindi, Thai,
Vietnamese, Tagalog, Russian, Italian, and Turkish. Pick one in Settings → Language; the choice is
stored in `shared_preferences` under `languageCode`.

- Strings live in `lib/l10n/app_<code>.arb`. `app_en.arb` is the template; every other file has the
  same 205 keys.
- The Dart code (`app_localizations.dart`) is **generated** by `flutter gen-l10n` and is not committed.
  **GitHub Actions runs it for you** before every build, so you do not need it on Termux.
- Motivation quotes live in `lib/utils/motivation_quotes.dart` as a `languageCode -> List<String>` map.
- The non-English translations were not reviewed by native speakers. Corrections are welcome.

## Build locally (optional)

```bash
flutter create --platforms=android --org com.projectcalendar --project-name project_calendar .
rm -rf test android/app/src/main/kotlin/com/projectcalendar/project_calendar
flutter pub get          # also runs gen-l10n because pubspec has `generate: true`
flutter run
```

The `flutter create` step only fills in what is missing (Gradle wrapper, launcher icons,
`launch_background`); it never overwrites files that are already in this repo.

## Build the APK with GitHub Actions (Termux-friendly)

### 1. Create a keystore

```bash
pkg install openjdk-17
keytool -genkeypair -v -keystore keystore.jks -alias projectcalendar \
  -keyalg RSA -keysize 2048 -validity 10000
```

Keep `keystore.jks` and its passwords somewhere safe. They are already ignored by `.gitignore`.

### 2. Base64-encode it

```bash
base64 -w 0 keystore.jks > keystore.b64
cat keystore.b64
```

Copy the whole single line.

### 3. Add four GitHub Secrets

Repository → Settings → Secrets and variables → Actions → New repository secret:

| Secret | Value |
|---|---|
| `KEYSTORE_BASE64` | contents of `keystore.b64` |
| `KEYSTORE_PASSWORD` | keystore password |
| `KEY_ALIAS` | `projectcalendar` (the `-alias` you used) |
| `KEY_PASSWORD` | key password |

Without these secrets the workflow still runs and builds a debug APK, with a warning in the log.

### 4. Push and download the APK

```bash
git init && git add . && git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/USERNAME/project_calendar.git
git push -u origin main
```

Open the **Actions** tab → latest run → **Artifacts**, or the **Releases** tab for per-ABI APKs.
On a modern phone pick `app-arm64-v8a-release.apk`.

## License

Copyright © 2026 Abi Manyu. All rights reserved.

Licensed under the MIT License. See [LICENSE](LICENSE) for details.
