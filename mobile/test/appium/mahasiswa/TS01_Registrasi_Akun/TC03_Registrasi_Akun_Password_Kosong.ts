/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-003
 * Skenario ID : TS-MHS-001
 * Modul / Fitur: Autentikasi
 * Judul Test Case: Registrasi mahasiswa dengan password kosong
 * Tipe Kasus  : Negatif
 * Prioritas   : Sedang
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Halaman registrasi terbuka.
 * Langkah      : 1. Kosongkan password
 *               2. Submit
 * Expected Result: Sistem menampilkan validasi password wajib diisi
 */

import { browser, expect, $ } from '@wdio/globals';

describe('TC-MHS-003 - Registrasi mahasiswa dengan password kosong', () => {
  before(async () => {
    // Pre-condition: halaman registrasi terbuka.
    await browser.pause(2000);
  });

  it('should show validation when password is empty', async () => {
    // Langkah Pengujian:
    // 1. Kosongkan password
    // 2. Submit
    //
    // Expected Result: Sistem menampilkan validasi password wajib diisi

    await browser.pause(2000);

    const bukaRegistrasiButton = await $(
      '~Daftar'
    );
    await bukaRegistrasiButton.click();
    await browser.pause(2000);

    const passwordField = await $(
      'android=new UiSelector().className("android.widget.EditText").instance(3)'
    );
    await passwordField.setValue('');

    const submitButton = await $(
      '~Lanjut ke Scan Wajah →'
    );
    await submitButton.click();
    await browser.pause(3000);

    // Assertion: validasi password wajib diisi ditampilkan.
    await expect($('~Password wajib diisi.')).toBeDisplayed();
  });
});
