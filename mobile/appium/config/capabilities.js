const path = require('node:path');

const role = process.env.APP_ROLE || 'student';
const apkPath =
  process.env.APP_PATH ||
  path.resolve(
    __dirname,
    '../../build/app/outputs/flutter-apk/app-debug.apk',
  );

module.exports = {
  role,
  capabilities: {
    platformName: 'Android',
    'appium:automationName': 'Flutter',
    'appium:deviceName': process.env.DEVICE_NAME || 'Android Emulator',
    'appium:app': apkPath,
    'appium:appWaitActivity': 'com.example.mobile.MainActivity',
    'appium:autoGrantPermissions': true,
    'appium:noReset': false,
  },
};
