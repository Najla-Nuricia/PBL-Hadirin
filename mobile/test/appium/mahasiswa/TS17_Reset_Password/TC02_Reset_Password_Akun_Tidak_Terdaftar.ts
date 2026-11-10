/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-038
 * Skenario ID  : TS-MHS-017
 * Judul Test Case: Reset password dengan akun tidak terdaftar
 * Tipe Kasus   : Negatif
 * Prioritas    : Tinggi
 */

import { browser } from '@wdio/globals';

describe('TC-MHS-038 - Reset password dengan akun tidak terdaftar', () => {
  it.skip('should reject an unregistered account without changing data', async () => {
    // Blocked: aplikasi saat ini belum menyediakan halaman reset password.
    await browser.pause(1);
  });
});
