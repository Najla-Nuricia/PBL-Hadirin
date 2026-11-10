const assert = require('node:assert/strict');
const { remote } = require('webdriverio');
const { capabilities } = require('../../../appium/config/capabilities');

describe('Dosen - login', function () {
  this.timeout(120000);
  let driver;

  before(async () => {
    driver = await remote({
      hostname: process.env.APPIUM_HOST || '127.0.0.1',
      port: Number(process.env.APPIUM_PORT || 4723),
      path: '/wd/hub',
      logLevel: 'warn',
      capabilities,
    });
  });

  after(async () => {
    if (driver) await driver.deleteSession();
  });

  it('opens the lecturer login screen', async () => {
    const source = await driver.getPageSource();
    assert.match(source, /Login Dosen/);
  });
});
