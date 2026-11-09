/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-023
 * Skenario ID : TS-MHS-010
 * Modul / Fitur: Face Recognition
 * Judul Test Case: Deteksi wajah dari kamera
 * Tipe Kasus  : Positif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Kamera aktif.
 * Langkah      : 1. Arahkan wajah ke kamera
 * Expected Result: Wajah terdeteksi
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-023 - Deteksi wajah dari kamera', () => {
  before(async () => {
    // Pre-condition: kamera aktif.
    await mahasiswaLogin( HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim, HADIRIN_DEMO_ACCOUNTS.mahasiswa.password, );
  });

  it('should detect face from camera', async () => {
    // Langkah Pengujian:
    // 1. Arahkan wajah ke kamera
    //
    // Expected Result: Wajah terdeteksi

    await browser.pause(2000);

    const arahkanKameraButton = await $(
      '~Scan Wajah'
    );
    await arahkanKameraButton.click();
    await browser.pause(5000);

    const hasilDeteksi = await $(
      '~Wajah terdeteksi! Absensi berhasil.'
    );
    await expect(hasilDeteksi).toBeDisplayed();
  });
});
