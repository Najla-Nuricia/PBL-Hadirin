import 'dotenv/config';
import { browser } from '@wdio/globals';
import { HADIRIN_ENV } from '../test/appium/src/support/env';

const capabilities = [
  {
    platformName: 'Android',
    'appium:platformVersion': HADIRIN_ENV.platformVersion,
    'appium:deviceName': HADIRIN_ENV.deviceName,
    'appium:automationName': 'UiAutomator2',
    ...(HADIRIN_ENV.appPath
      ? { 'appium:app': HADIRIN_ENV.appPath }
      : {
          'appium:appPackage': HADIRIN_ENV.appPackage,
          'appium:appActivity': HADIRIN_ENV.appActivity,
        }),
    'appium:noReset': false,
    'appium:autoGrantPermissions': true,
    'appium:newCommandTimeout': 120,
  },
];

export const config = {
  runner: 'local',
  specs: ['../test/appium/mahasiswa/**/*.ts'],
  maxInstances: 1,
  logLevel: 'info',
  waitforTimeout: 10000,
  connectionRetryTimeout: 120000,
  connectionRetryCount: 2,
  framework: 'mocha',
  reporters: ['spec'],
  mochaOpts: {
    ui: 'bdd',
    timeout: 60000,
  },
  before: async () => {
    await browser.pause(500);
  },
  services: [
    [
      'appium',
      {
        args: {
          port: HADIRIN_ENV.appiumPort,
          relaxedSecurity: true,
        },
      },
    ],
  ],
  capabilities,
};

export default config;
