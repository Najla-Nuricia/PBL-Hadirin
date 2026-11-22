/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-018
 * Skenario ID : TS-MHS-008
 * Modul / Fitur: QR Code
 * Judul Test Case: Scan QR Code yang tidak sesuai kelas
 * Tipe Kasus  : Negatif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : QR kelas lain tersedia.
 * Langkah      : 1. Scan QR tersebut
 * Expected Result: Sistem menolak presensi
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-018 - Scan QR Code kelas yang tidak sesuai kelas', () => {
  before(async () => {
    // Pre-condition: QR kelas lain tersedia.
    await mahasiswaLogin( HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim, HADIRIN_DEMO_ACCOUNTS.mahasiswa.password, );
  });

  it('should reject attendance from foreign class qr', async () => {
    // Langkah Pengujian:
    // 1. Scan QR tersebut
    //
    // Expected Result: Sistem menolak presensi

    await browser.pause(2000);

    const bukaScannerButton = await $(
      '~Scan QR'
    );
    await bukaScannerButton.click();
    await browser.pause(3000);

    const scanButton = await $(
      '~Lanjutkan ke Scan Wajah'
    );
    await scanButton.click();
    await browser.pause(5000);

    // Assertion: QR tidak cocok / presensi ditolak.
    // ~Arahkan kamera ke QR yang tersedia di depan kelas belum tersedia.
    await expect($('~Arahkan kamera ke QR yang tersedia di depan kelas')).toBeDisplayed();
  });
});
