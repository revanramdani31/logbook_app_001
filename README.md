# LogBook App

Aplikasi Flutter untuk pencatatan log dengan dukungan penyimpanan lokal, koneksi MongoDB, dan akses kamera.

## Prasyarat

Sebelum instalasi, pastikan perangkat sudah memiliki:

- Flutter SDK versi 3.10.8 atau yang kompatibel
- Dart SDK bawaan Flutter
- Android Studio atau Visual Studio Code
- Git
- Koneksi internet untuk mengunduh dependency
- Jika target desktop dipakai, siapkan juga CMake dan toolchain build sesuai platform

### Android Studio Untuk Apa?

Android Studio dipakai untuk menyiapkan environment Android saat menjalankan aplikasi Flutter.

- Android SDK: alat utama untuk build dan menjalankan aplikasi Android.
- Android SDK Platform Tools: berisi `adb` untuk koneksi ke device dan emulator.
- Android Emulator: dipakai kalau Anda tidak memakai HP fisik.
- Android SDK Command-line Tools: dibutuhkan Flutter untuk beberapa perintah build dan setup.
- Android NDK: diperlukan jika ada dependency native seperti OpenCV pada proses build Android.

Kalau Anda hanya ingin menjalankan app di Android, biasanya cukup install Android Studio lalu aktifkan komponen di atas lewat SDK Manager.

## Instalasi

1. Clone repository ini ke komputer Anda.

  ```bash
  git clone <url-repository>
  cd logbook_app_001
  ```

2. Install seluruh dependency Flutter.

  ```bash
  flutter pub get
  ```

3. Buat file `.env` di root project.

  File ini dibaca langsung saat aplikasi dijalankan, jadi wajib ada sebelum `flutter run`.

  ```env
  MONGODB_URI=your_mongodb_connection_string
  APP_ROLES=admin,user
  LOG_LEVEL=2
  LOG_MUTE=
  ```

4. Jika Anda mengubah model Hive, jalankan generator bila diperlukan.

  ```bash
  flutter pub run build_runner build --delete-conflicting-outputs
  ```

5. Jalankan aplikasi.

  ```bash
  flutter run
  ```

## Catatan Untuk OpenCV

Project ini memakai `opencv_dart` untuk proses OpenCV di fitur vision, jadi OpenCV biasanya tidak perlu di-install manual.

- Saat `flutter pub get` atau build pertama dijalankan, dependency native OpenCV akan disiapkan otomatis oleh paket.
- Jika Anda menjalankan target desktop seperti Windows, Linux, atau macOS, pastikan tool build platform tersebut sudah terpasang karena proses OpenCV ikut dibangun lewat toolchain Flutter/CMake.
- Untuk Android, pastikan Android SDK dan NDK sudah tersedia di Android Studio.
- Jika build pertama terasa lama, itu normal karena paket perlu menyiapkan native asset OpenCV.

## Catatan Penting

- Aplikasi akan gagal start jika file `.env` belum dibuat.
- `MONGODB_URI` harus berisi connection string MongoDB Atlas atau server MongoDB yang aktif.
- Fitur kamera membutuhkan izin kamera pada perangkat fisik atau emulator yang mendukung kamera.
- Data offline disimpan menggunakan Hive di storage lokal perangkat.

## Build Aplikasi

Untuk membuat build release:

```bash
flutter build apk
```

Atau untuk platform lain, sesuaikan dengan target yang digunakan, misalnya `flutter build ios` atau `flutter build windows`.

## Struktur Singkat

- `lib/main.dart` digunakan sebagai titik masuk aplikasi.
- `lib/features/` berisi fitur utama seperti onboarding, auth, logbook, dan vision.
- `lib/services/` berisi layanan seperti MongoDB dan access control.
- `assets/` berisi aset statis yang dipakai aplikasi.

## Teknologi Utama

- Flutter
- Hive
- MongoDB
- Camera
- Permission Handler
- Flutter Dotenv
