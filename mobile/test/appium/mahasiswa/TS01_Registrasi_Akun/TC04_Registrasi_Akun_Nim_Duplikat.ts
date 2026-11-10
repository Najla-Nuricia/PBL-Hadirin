/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-004
 * Skenario ID : TS-MHS-001
 * Modul / Fitur: Autentikasi
 * Judul Test Case: Registrasi mahasiswa dengan NIM yang sudah terdaftar
 * Tipe Kasus  : Negatif
 * Prioritas   : Sedang
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Halaman registrasi terbuka; NIM sudah ada di database.
 * Langkah      : 1. Masukkan NIM terdaftar
 *               2. Submit
 * Expected Result: Sistem menolak registrasi dan menampilkan pesan
 */

import { browser, expect, $ } from '@wdio/globals';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-004 - Registrasi mahasiswa dengan NIM sudah terdaftar', () => {
  before(async () => {
    // Pre-condition: halaman registrasi terbuka.
    await browser.pause(2000);
  });

  it('should reject registration when nim already registered', async () => {
    // Langkah Pengujian:
    // 1. Masukkan NIM terdaftar
    // 2. Submit
    //
    // Expected Result: Sistem menolak registrasi dan menampilkan pesan

    await browser.pause(2000);

    const bukaRegistrasiButton = await $(
      '~Daftar'
    );
    await bukaRegistrasiButton.click();
    await browser.pause(2000);

    const nimField = await $(
      'android=new UiSelector().className("android.widget.EditText").instance(1)'
    );
    await nimField.setValue(HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim);

    const submitButton = await $(
      '~Lanjut ke Scan Wajah →'
    );
    await submitButton.click();
    await browser.pause(3000);

    // Assertion: registrasi ditolak dan pesan NIM sudah terdaftar ditampilkan.
    // ~NIM sudah terdaftar. Silakan login. belum tersedia.
    await expect($('~NIM sudah terdaftar. Silakan login.')).toBeDisplayed();
  });
});
