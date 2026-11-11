/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-039
 * Skenario ID  : TS-MHS-018
 * Modul / Fitur: Logout
 * Judul Test Case: Logout akun mahasiswa
 * Tipe Kasus   : Positif
 * Prioritas    : Tinggi
 *
 * Pre-kondisi  : Mahasiswa sudah login.
 * Langkah      : 1. Buka menu Profil
 *               2. Klik tombol Keluar
 * Expected Result: Mahasiswa diarahkan ke halaman login.
 */

import { browser, expect, $ } from '@wdio/globals';
import { goToStudentTab, mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-039 - Logout akun mahasiswa', () => {
  before(async () => {
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should logout the student account', async () => {
    await goToStudentTab('Profil');

    const logoutButton = await $('~Keluar');
    await logoutButton.waitForDisplayed({ timeout: 10000 });
    await logoutButton.click();

    await expect($('~Login Mahasiswa')).toBeDisplayed();
  });
});
