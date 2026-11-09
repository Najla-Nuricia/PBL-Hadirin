/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-011
 * Skenario ID : TS-MHS-004
 * Modul / Fitur: Account
 * Judul Test Case: Melihat informasi akun
 * Tipe Kasus  : Positif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Mahasiswa sudah login.
 * Langkah      : 1. Buka menu akun
 * Expected Result: Informasi akun mahasiswa ditampilkan
 */

import { browser, expect, $ } from '@wdio/globals';
import { goToStudentTab, mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-011 - Melihat informasi akun mahasiswa', () => {
  before(async () => {
    // Pre-condition: mahasiswa sudah login.
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should display account information', async () => {
    // Langkah Pengujian:
    // 1. Buka menu akun
    //
    // Expected Result: Informasi akun mahasiswa ditampilkan

    await browser.pause(3000);
    await goToStudentTab('Profil');

    // Assertion: halaman informasi akun tampil.
    await expect($('android=new UiSelector().text("Informasi Akun")')).toBeDisplayed();
  });
});
