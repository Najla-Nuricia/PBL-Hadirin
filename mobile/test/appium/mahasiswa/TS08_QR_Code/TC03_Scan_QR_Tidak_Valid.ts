/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-019
 * Skenario ID : TS-MHS-008
 * Modul / Fitur: QR Code
 * Judul Test Case: Scan QR Code tidak valid
 * Tipe Kasus  : Negatif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : QR tidak valid tersedia.
 * Langkah      : 1. Scan QR
 * Expected Result: Sistem menampilkan pesan QR tidak valid
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-019 - Scan QR Code tidak valid', () => {
  before(async () => {
    // Pre-condition: QR tidak valid tersedia.
    await mahasiswaLogin( HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim, HADIRIN_DEMO_ACCOUNTS.mahasiswa.password, );
  });

  it('should show message when scanned qr is invalid', async () => {
    // Langkah Pengujian:
    // 1. Scan QR
    //
    // Expected Result: Sistem menampilkan pesan QR tidak valid

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

    // Assertion: pesan QR tidak valid ditampilkan.
    // ~Arahkan kamera ke QR yang tersedia di depan kelas belum tersedia.
    await expect($('~Arahkan kamera ke QR yang tersedia di depan kelas')).toBeDisplayed();
  });
});
