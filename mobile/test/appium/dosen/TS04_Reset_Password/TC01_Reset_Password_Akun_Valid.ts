import { browser } from '@wdio/globals';

describe('TC-DOSEN-034 - Reset password dengan akun valid', () => {
  it.skip('should reset password from the login screen', async () => {
    // Blocked: aplikasi dosen masih menampilkan fitur lupa password sebagai belum tersedia.
    await browser.pause(1);
  });
});
