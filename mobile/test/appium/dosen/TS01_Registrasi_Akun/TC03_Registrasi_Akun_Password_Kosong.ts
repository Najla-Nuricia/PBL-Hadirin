import { expect, $ } from '@wdio/globals';
import {
  fillField,
  openLecturerRegistration,
  tapSubmitLecturerRegistration,
} from '../../src/support/actions';
import { LOCATORS } from '../../src/support/selectors';

describe('TC-DOSEN-003 - Registrasi dosen dengan password kosong', () => {
  it('should show validation when password is empty', async () => {
    await openLecturerRegistration();

    await fillField(LOCATORS.dosen.register.fullNameField, 'Dosen Appium');
    await fillField(LOCATORS.dosen.register.staffIdField, '1985061520121006');
    await fillField(
      LOCATORS.dosen.register.emailField,
      `dosen.password-kosong.${Date.now()}@hadirin.id`,
    );
    await fillField(LOCATORS.dosen.register.passwordField, '');
    await fillField(LOCATORS.dosen.register.confirmPasswordField, 'appium123');

    await tapSubmitLecturerRegistration();

    await expect($('~Kata sandi wajib diisi.')).toBeDisplayed();
  });
});
