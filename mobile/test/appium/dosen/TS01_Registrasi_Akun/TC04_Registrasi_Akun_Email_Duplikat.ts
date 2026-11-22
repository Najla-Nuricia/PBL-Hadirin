import { expect, $ } from '@wdio/globals';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';
import {
  fillField,
  openLecturerRegistration,
  tapSubmitLecturerRegistration,
} from '../../src/support/actions';
import { LOCATORS } from '../../src/support/selectors';

describe('TC-DOSEN-004 - Registrasi dosen dengan email duplikat', () => {
  it('should reject registration when email is already registered', async () => {
    await openLecturerRegistration();

    await fillField(LOCATORS.dosen.register.fullNameField, 'Dosen Duplikat');
    await fillField(LOCATORS.dosen.register.staffIdField, '1985061520121007');
    await fillField(
      LOCATORS.dosen.register.emailField,
      HADIRIN_DEMO_ACCOUNTS.dosen.email,
    );
    await fillField(LOCATORS.dosen.register.passwordField, 'appium123');
    await fillField(LOCATORS.dosen.register.confirmPasswordField, 'appium123');

    await tapSubmitLecturerRegistration();

    await expect($('~Email sudah terdaftar. Silakan login.')).toBeDisplayed();
  });
});
