/**
 * Environment & demo account constants for the Hadirin QA suite.
 *
 * Values marked as demo are the seeded accounts of the Flutter prototype
 * (see `lib/data/mhs/dummy_student_auth_repository.dart`,
 * `lib/pages/dosen/auth/lecturer_login_page.dart` and
 * `lib/pages/admin/auth/admin_login_page.dart` in the PBL-Hadirin repo).
 */

export const HADIRIN_DEMO_ACCOUNTS = {
  admin: {
    username: 'admin',
    password: '123',
  },
  mahasiswa: {
    nim: '2341720001',
    password: 'mahasiswa123',
  },
  dosen: {
    email: 'dosen@hadirin.id',
    password: 'dosen123',
  },
} as const;

export const HADIRIN_ENV = {
  appiumPort: Number(process.env.APPIUM_PORT ?? 4723),
  deviceName: process.env.ANDROID_DEVICE_NAME ?? '13313704BS006358',
  platformVersion: process.env.ANDROID_PLATFORM_VERSION ?? '14',
  appPackage: process.env.FLUTTER_APP_PACKAGE ?? 'com.example.mobile',
  appActivity: process.env.FLUTTER_APP_ACTIVITY ?? 'com.example.mobile.MainActivity',
  appPath: process.env.FLUTTER_APP_PATH,
} as const;
