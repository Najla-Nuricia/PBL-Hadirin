import { expect, $ } from '@wdio/globals';
import {
  dosenLogin,
  goToLecturerTab,
  tapProfileChangePassword,
} from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';
import { LOCATORS } from '../../src/support/selectors';

describe('TC-DOSEN-037 - Ubah kata sandi setelah login', () => {
  before(async () => {
    await dosenLogin(
      HADIRIN_DEMO_ACCOUNTS.dosen.email,
      HADIRIN_DEMO_ACCOUNTS.dosen.password,
    );
  });

  it('should update the lecturer password successfully', async () => {
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
    await newPasswordField.setValue('dosen456');
    await confirmationField.click();
    await confirmationField.setValue('dosen456');
    await $(LOCATORS.dosen.changePassword.submitButton).click();

    await expect(
      $(LOCATORS.dosen.changePassword.successSnackbar),
    ).toBeDisplayed();
  });
});
