import { expect, $ } from '@wdio/globals';
import {
  dosenLogin,
  goToLecturerTab,
  tapProfileChangePassword,
} from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';
import { LOCATORS } from '../../src/support/selectors';

describe('TC-DOSEN-036 - Password baru kurang dari 8 karakter', () => {
  before(async () => {
    await dosenLogin(
      HADIRIN_DEMO_ACCOUNTS.dosen.email,
      HADIRIN_DEMO_ACCOUNTS.dosen.password,
    );
  });

  it('should reject a new password shorter than eight characters', async () => {
    await goToLecturerTab('Profil');
    await tapProfileChangePassword(LOCATORS.dosen.profile.changePassword);

    const currentPasswordField = await $(
      LOCATORS.dosen.changePassword.currentPasswordField,
    );
    const newPasswordField = await $(
      LOCATORS.dosen.changePassword.newPasswordField,
    );
    const confirmationField = await $(
      LOCATORS.dosen.changePassword.confirmationField,
    );

    await currentPasswordField.click();
    await currentPasswordField.setValue(
      HADIRIN_DEMO_ACCOUNTS.dosen.password,
    );
    await newPasswordField.click();
    await newPasswordField.setValue('short');
    await confirmationField.click();
    await confirmationField.setValue('short');
    await $(LOCATORS.dosen.changePassword.submitButton).click();

    await expect($('~Kata sandi minimal 8 karakter.')).toBeDisplayed();
  });
});
