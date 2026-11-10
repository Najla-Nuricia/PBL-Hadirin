/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-025
 * Skenario ID : TS-MHS-010
 * Modul / Fitur: Face Recognition
 * Judul Test Case: Tidak ada wajah pada kamera
 * Tipe Kasus  : Negatif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Kamera aktif.
 * Langkah      : 1. Arahkan kamera tanpa wajah
 * Expected Result: Sistem tidak melakukan verifikasi dan meminta wajah
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-025 - Deteksi wajah ketika tidak ada wajah', () => {
  before(async () => {
    // Pre-condition: kamera aktif.
    await mahasiswaLogin( HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim, HADIRIN_DEMO_ACCOUNTS.mahasiswa.password, );
  });

  it('should not verify when no face is present', async () => {
    // Langkah Pengujian:
    // 1. Arahkan kamera tanpa wajah
    //
    // Expected Result: Sistem tidak melakukan verifikasi dan meminta wajah

    await browser.pause(2000);

    const arahkanKameraButton = await $(
      '~Scan Wajah'
    );
    await arahkanKameraButton.click();
    await browser.pause(5000);

    const hasilDeteksi = await $(
      '~Arahkan kamera ke QR yang tersedia di depan kelas'
    );
    await expect(hasilDeteksi).toBeDisplayed();
  });
});
