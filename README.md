# Project Calendar

Aplikasi manajemen project berbasis kalender (Android, Flutter, Material 3). Antarmuka berbahasa Indonesia.

## Cara kerja build

Repo ini hanya berisi kode inti. Folder Android yang di-*generate* (gradlew, ikon, `launch_background`) dibuat otomatis oleh langkah `flutter create` di CI tanpa menimpa file yang sudah ada. Untuk build lokal, jalankan sekali:

```bash
flutter create --platforms=android --org com.projectcalendar --project-name project_calendar .
rm -rf test android/app/src/main/kotlin/com/projectcalendar/project_calendar
flutter pub get
flutter run
```

## 1. Buat keystore (Termux-friendly)

```bash
pkg install openjdk-17
keytool -genkeypair -v -keystore keystore.jks -alias projectcalendar \
  -keyalg RSA -keysize 2048 -validity 10000
```

Simpan `keystore.jks` dan password-nya di tempat aman. Jangan di-commit (sudah ada di `.gitignore`).

## 2. Base64 keystore

```bash
base64 -w 0 keystore.jks > keystore.b64
cat keystore.b64
```

Salin seluruh isinya (satu baris).

## 3. Tambah 4 GitHub Secrets

Repo → Settings → Secrets and variables → Actions → New repository secret:

| Secret | Isi |
|---|---|
| `KEYSTORE_BASE64` | isi `keystore.b64` |
| `KEYSTORE_PASSWORD` | password keystore |
| `KEY_ALIAS` | `projectcalendar` (sesuai `-alias`) |
| `KEY_PASSWORD` | password key |

Tanpa secrets, workflow tetap jalan dan membangun APK debug (dengan peringatan di log).

## 4. Push dan unduh APK

```bash
git init && git add . && git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/USERNAME/project_calendar.git
git push -u origin main
```

Buka tab **Actions** → run terbaru → **Artifacts**, atau tab **Releases** untuk APK per-ABI. Pada HP modern pilih `app-arm64-v8a-release.apk`.

## Font

Font default ada di `assets/fonts/minecraft.ttf`. Jika file hilang/kosong saat runtime, app otomatis memakai PressStart2P (google_fonts, butuh internet saat pertama), lalu font sistem. Catatan: `pubspec.yaml` mendeklarasikan aset ini, jadi file harus ada saat build.
