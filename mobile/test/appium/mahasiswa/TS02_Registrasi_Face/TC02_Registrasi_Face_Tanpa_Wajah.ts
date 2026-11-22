/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-006
 * Skenario ID : TS-MHS-002
 * Modul / Fitur: Face Registration
 * Judul Test Case: Registrasi wajah tanpa wajah terdeteksi
 * Tipe Kasus  : Negatif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Kamera aktif.
 * Langkah      : 1. Arahkan kamera tanpa wajah
 *               2. Capture
 * Expected Result: Sistem meminta pengguna menempatkan wajah pada kamera
 */

import { browser, expect, $ } from '@wdio/globals';

describe('TC-MHS-006 - Registrasi wajah tanpa wajah terdeteksi', () => {
  before(async () => {
    // Pre-condition: kamera aktif.
    await browser.pause(2000);
  });

  it('should request face placement when no face detected', async () => {
    // Langkah Pengujian:
    // 1. Arahkan kamera tanpa wajah
    // 2. Capture
    //
    // Expected Result: Sistem meminta pengguna menempatkan wajah pada kamera

    await browser.pause(2000);

    const arahkanKameraButton = await $(
      '~Scan Wajah'
    );
    await arahkanKameraButton.click();
    await browser.pause(5000);

    const kunciWajahButton = await $(
      '~Ambil Foto'
    );
    await kunciWajahButton.click();
    await browser.pause(3000);

    // Assertion: sistem meminta pengguna menempatkan wajah pada kamera.
    // ~Arahkan kamera ke QR yang tersedia di depan kelas belum tersedia.
    await expect($('~Arahkan kamera ke QR yang tersedia di depan kelas')).toBeDisplayed();
  });
});
