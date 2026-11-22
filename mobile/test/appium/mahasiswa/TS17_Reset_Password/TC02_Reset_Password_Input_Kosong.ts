/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-039
 * Skenario ID  : TS-MHS-017
 * Judul Test Case: Reset password dengan input kosong
 * Tipe Kasus   : Negatif
 * Prioritas    : Tinggi
 */

import { browser } from '@wdio/globals';

describe('TC-MHS-039 - Reset password dengan input kosong', () => {
  it.skip('should validate required reset password input', async () => {
    // Blocked: aplikasi saat ini belum menyediakan halaman reset password.
    await browser.pause(1);
  });
});
