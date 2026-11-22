import { expect, $ } from '@wdio/globals';
import {
  fillField,
  openLecturerRegistration,
  tapSubmitLecturerRegistration,
} from '../../src/support/actions';
import { LOCATORS } from '../../src/support/selectors';

describe('TC-DOSEN-002 - Registrasi dosen dengan email kosong', () => {
  it('should show validation when email is empty', async () => {
    await openLecturerRegistration();

    await fillField(LOCATORS.dosen.register.fullNameField, 'Dosen Appium');
    await fillField(LOCATORS.dosen.register.staffIdField, '1985061520121005');
    await fillField(LOCATORS.dosen.register.emailField, '');
    await fillField(LOCATORS.dosen.register.passwordField, 'appium123');
    await fillField(LOCATORS.dosen.register.confirmPasswordField, 'appium123');

    await tapSubmitLecturerRegistration();

    await expect($('~Email wajib diisi.')).toBeDisplayed();
  });
});
