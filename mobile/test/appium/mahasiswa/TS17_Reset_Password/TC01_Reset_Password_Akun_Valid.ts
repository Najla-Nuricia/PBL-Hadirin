/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-037
 * Skenario ID  : TS-MHS-017
 * Judul Test Case: Reset password dengan data valid
 * Tipe Kasus   : Positif
 * Prioritas    : Tinggi
 */

import { browser } from '@wdio/globals';

describe('TC-MHS-037 - Reset password dengan akun valid', () => {
  it.skip('should reset password and allow login with the new password', async () => {
    // Blocked: aplikasi saat ini belum menyediakan halaman reset password.
    await browser.pause(1);
  });
});
