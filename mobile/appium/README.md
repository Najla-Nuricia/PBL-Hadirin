# Appium tests

Appium tests are kept separate from Flutter functional tests:

```text
test/
├── functional/          # Flutter unit, widget, and repository tests
└── appium/
    ├── admin/             # Smoke test role admin
    ├── dosen/             # Smoke test role dosen
    ├── mhs/               # Smoke test role mahasiswa
    └── mahasiswa/         # Seluruh TC Mahasiswa dari repo PBL-Hadirin-QA
```

## Prerequisites

- Flutter SDK and an Android emulator or device
- Node.js 18+
- Android SDK with `adb` available on `PATH`

Install the Appium dependencies:

```bash
cd appium
npm install
npx appium driver install uiautomator2
npx appium driver install --source=npm appium-flutter-driver
```

Run the app directly on the connected Android device. This is the recommended
way to run the TC because Flutter installs and starts the current source:

```bash
cd ..
flutter run -d <device-id> --dart-define=APP_ROLE=student
```

Supported values are `student`, `lecturer`, and any other value for the admin
router. Keep `flutter run` active in one terminal, then run the test suite in
another terminal:

Start Appium in one terminal:

```bash
cd appium
npm run appium
```

Then run the seluruh TC Mahasiswa from another terminal:

```bash
cd appium
npm run test:mhs:types
npm run test:mhs
```

Set `ANDROID_DEVICE_NAME` and `ANDROID_PLATFORM_VERSION` when they are not
detected automatically:

```bash
ANDROID_DEVICE_NAME=<device-id> ANDROID_PLATFORM_VERSION=14 npm run test:mhs
```

`FLUTTER_APP_PATH` is optional and is only needed when Appium should install an
APK directly instead of attaching to the app installed by `flutter run`.

The test cases are grouped under `test/appium/mahasiswa/TS*`, following the
scenario and TC folders from `PBL-Hadirin-QA`.
