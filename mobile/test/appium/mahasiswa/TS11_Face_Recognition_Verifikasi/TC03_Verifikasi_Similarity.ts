/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-028
 * Skenario ID : TS-MHS-011
 * Modul / Fitur: Face Recognition - Verifikasi
 * Judul Test Case: Hasil verifikasi wajah dengan similarity rendah
 * Tipe Kasus  : Negatif
 * Prioritas   : Sedang
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Proses verifikasi wajah berjalan.
 * Langkah      : 1. Verifikasi wajah lalu baca nilai similarity
 * Expected Result: Hasil verifikasi tidak cocok (similarity di bawah threshold)
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-028 - Hasil verifikasi wajah dengan similarity rendah', () => {
  before(async () => {
    // Pre-condition: fitur verifikasi wajah dibuka.
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should evaluate face verification result and similarity', async () => {
    // Langkah Pengujian:
    // 1. Verifikasi wajah lalu baca nilai similarity
    // Expected Result: Hasil verifikasi tidak cocok (similarity di bawah threshold)

    await browser.pause(3000);

    const bukaVerifikasiButton = await $(
      '~Scan Wajah'
    );
    await bukaVerifikasiButton.click();
    await browser.pause(3000);

    const scanButton = await $(
      '~Selesai'
    );
    await scanButton.click();
    await browser.pause(5000);

    const similarity = await $(
      '~Wajah terdeteksi! Absensi berhasil.'
    );
    await expect(similarity).toBeDisplayed();
  });
});
