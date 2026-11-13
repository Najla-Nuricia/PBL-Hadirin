import { expect, $ } from '@wdio/globals';
import {
  dosenLogin,
  goToLecturerTab,
} from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';
import { LOCATORS } from '../../src/support/selectors';

describe('TC-DOSEN-035 - Ubah kata sandi dengan input kosong', () => {
  before(async () => {
    await dosenLogin(
      HADIRIN_DEMO_ACCOUNTS.dosen.email,
      HADIRIN_DEMO_ACCOUNTS.dosen.password,
    );
  });

  it('should show required validation for empty input', async () => {
    await goToLecturerTab('Profil');
    await $(LOCATORS.dosen.profile.changePassword).click();
    await $(LOCATORS.dosen.changePassword.submitButton).click();

    await expect($('~Kata sandi saat ini wajib diisi.')).toBeDisplayed();
  });
});
