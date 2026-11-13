import { expect, $ } from '@wdio/globals';
import {
  dosenLogin,
  goToLecturerTab,
} from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';
import { LOCATORS } from '../../src/support/selectors';

describe('TC-DOSEN-039 - Logout akun dosen', () => {
  before(async () => {
    await dosenLogin(
      HADIRIN_DEMO_ACCOUNTS.dosen.email,
      HADIRIN_DEMO_ACCOUNTS.dosen.password,
    );
  });

  it('should logout the lecturer account', async () => {
    await goToLecturerTab('Profil');
    await $(LOCATORS.dosen.profile.logout).click();
    await $('//*[contains(@text,"Keluar")]').click();

    await expect($('~Login Dosen')).toBeDisplayed();
  });
});
