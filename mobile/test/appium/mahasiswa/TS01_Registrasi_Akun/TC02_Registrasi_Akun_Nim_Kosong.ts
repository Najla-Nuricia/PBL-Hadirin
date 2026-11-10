/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-002
 * Skenario ID : TS-MHS-001
 * Modul / Fitur: Autentikasi
 * Judul Test Case: Registrasi mahasiswa dengan NIM kosong
 * Tipe Kasus  : Negatif
 * Prioritas   : Sedang
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Halaman registrasi terbuka.
 * Langkah      : 1. Kosongkan NIM
 *               2. Submit
 * Expected Result: Sistem menampilkan validasi NIM wajib diisi
 */

import { browser, expect, $ } from '@wdio/globals';

describe('TC-MHS-002 - Registrasi mahasiswa dengan NIM kosong', () => {
  before(async () => {
    // Pre-condition: halaman registrasi terbuka.
    await browser.pause(2000);
  });

  it('should show validation when nim is empty', async () => {
    // Langkah Pengujian:
    // 1. Kosongkan NIM
    // 2. Submit
    //
    // Expected Result: Sistem menampilkan validasi NIM wajib diisi

    await browser.pause(2000);

    const bukaRegistrasiButton = await $(
      '~Daftar'
    );
    await bukaRegistrasiButton.click();
    await browser.pause(2000);

    const nimField = await $(
      'android=new UiSelector().className("android.widget.EditText").instance(1)'
    );
    await nimField.setValue('');

    const submitButton = await $(
      '~Lanjut ke Scan Wajah →'
    );
    await submitButton.click();
    await browser.pause(3000);

    // Assertion: validasi NIM wajib diisi ditampilkan.
    await expect($('~NIM wajib diisi.')).toBeDisplayed();
  });
});
