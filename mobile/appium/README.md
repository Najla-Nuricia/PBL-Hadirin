# Appium tests

Appium tests are kept separate from Flutter functional tests:

```text
test/
├── functional/          # Flutter unit, widget, and repository tests
└── appium/
    ├── admin/            # Test case untuk role admin
    ├── dosen/            # Test case untuk role dosen
    └── mhs/              # Test case untuk role mahasiswa
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

Build the APK for the role under test. `APP_ROLE` is read by `lib/main.dart`:

```bash
cd ..
flutter build apk --debug --dart-define=APP_ROLE=student
```

Supported values are `student`, `lecturer`, and any other value for the admin
router. Use the matching npm script for the APK that was built:

Start Appium in one terminal:

```bash
cd appium
npm run appium
```

Then run the tests from another terminal:

```bash
cd appium
npm run test:mhs
```

Use `APP_PATH` when the APK is stored elsewhere, and `DEVICE_NAME` when the
connected device is not named `Android Emulator`.
