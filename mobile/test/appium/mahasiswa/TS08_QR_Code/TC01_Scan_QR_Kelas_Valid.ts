/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-017
 * Skenario ID : TS-MHS-008
 * Modul / Fitur: QR Code
 * Judul Test Case: Scan QR Code kelas yang valid
 * Tipe Kasus  : Positif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Kelas sedang berlangsung.
 * Langkah      : 1. Buka scanner
 *               2. Scan QR kelas
 * Expected Result: QR berhasil diverifikasi
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-017 - Scan QR Code kelas yang valid', () => {
  before(async () => {
    // Pre-condition: kelas sedang berlangsung.
    await mahasiswaLogin( HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim, HADIRIN_DEMO_ACCOUNTS.mahasiswa.password, );
  });

  it('should verify valid class qr code', async () => {
    // Langkah Pengujian:
    // 1. Buka scanner
    // 2. Scan QR kelas
    //
    // Expected Result: QR berhasil diverifikasi

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

    // Assertion: scanner QR terbuka dan hasil verifikasi tampil.
    // ~QR Code terdeteksi! Silakan lanjutkan. belum tersedia.
    await expect($('~QR Code terdeteksi! Silakan lanjutkan.')).toBeDisplayed();
  });
});
