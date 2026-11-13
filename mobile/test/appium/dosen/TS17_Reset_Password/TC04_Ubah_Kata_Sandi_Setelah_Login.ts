import { expect, $ } from '@wdio/globals';
import {
  dosenLogin,
  goToLecturerTab,
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
    await $(LOCATORS.dosen.profile.changePassword).click();

    await $(
      LOCATORS.dosen.changePassword.currentPasswordField,
    ).setValue(HADIRIN_DEMO_ACCOUNTS.dosen.password);
    await $(LOCATORS.dosen.changePassword.newPasswordField).setValue(
      'dosen456',
    );
    await $(LOCATORS.dosen.changePassword.confirmationField).setValue(
      'dosen456',
    );
    await $(LOCATORS.dosen.changePassword.submitButton).click();

    await expect(
      $(LOCATORS.dosen.changePassword.successSnackbar),
    ).toBeDisplayed();
  });
});
