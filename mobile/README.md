# mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
online documentation, which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Menjalankan dengan backend lokal

Default base URL di `lib/data/api_config.dart` adalah `http://10.0.2.2:8000`
(emulator Android). Perangkat fisik tidak bisa memakai alamat itu, jadi pilih
salah satu:

- **Lewat kabel USB (adb reverse)** — paling cepat:
  ```bash
  adb reverse tcp:8000 tcp:8000
  flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
  ```
- **Lewat Wi-Fi** — HP dan PC harus satu jaringan, backend bind ke `0.0.0.0`:
  ```bash
  flutter run --dart-define=API_BASE_URL=http://<IP-PC>:8000
  ```

`android:usesCleartextTraffic="true"` sudah diaktifkan di `AndroidManifest.xml`
agar HTTP lokal tidak diblokir Android 9+. Untuk build produksi, gunakan HTTPS
dan hapus flag tersebut.
