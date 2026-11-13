import { expect, $ } from '@wdio/globals';
import {
  fillField,
  openLecturerRegistration,
  tapSubmitLecturerRegistration,
} from '../../src/support/actions';
import { LOCATORS } from '../../src/support/selectors';

describe('TC-DOSEN-001 - Registrasi dosen dengan data valid', () => {
  it('should register a lecturer with valid data', async () => {
    await openLecturerRegistration();

    await fillField(LOCATORS.dosen.register.fullNameField, 'Dosen Appium');
    await fillField(LOCATORS.dosen.register.staffIdField, '1985061520121004');
    await fillField(
      LOCATORS.dosen.register.emailField,
      `dosen.appium.${Date.now()}@hadirin.id`,
    );
    await fillField(LOCATORS.dosen.register.passwordField, 'appium123');
    await fillField(LOCATORS.dosen.register.confirmPasswordField, 'appium123');

    await tapSubmitLecturerRegistration();

    await expect(
      $('~Registrasi dosen berhasil. Silakan login.'),
    ).toBeDisplayed();
  });
});
