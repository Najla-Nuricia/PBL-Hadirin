import { expect, $ } from '@wdio/globals';
import { dosenLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-DOSEN-008 - Login dosen dengan akun valid', () => {
  before(async () => {
    await dosenLogin(
      HADIRIN_DEMO_ACCOUNTS.dosen.email,
      HADIRIN_DEMO_ACCOUNTS.dosen.password,
    );
  });

  it('should open the lecturer dashboard', async () => {
    await expect($('~Cek Daftar Presensi')).toBeDisplayed();
  });
});
