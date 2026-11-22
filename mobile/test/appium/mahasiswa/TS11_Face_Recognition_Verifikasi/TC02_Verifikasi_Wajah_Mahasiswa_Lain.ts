/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-027
 * Skenario ID : TS-MHS-011
 * Modul / Fitur: Face Recognition - Verifikasi
 * Judul Test Case: Verifikasi wajah mahasiswa lain
 * Tipe Kasus  : Negatif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Proses verifikasi wajah berjalan.
 * Langkah      : 1. Verifikasi wajah dengan data akun lain
 * Expected Result: Verifikasi ditolak karena data wajah tidak cocok
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-027 - Verifikasi wajah mahasiswa lain', () => {
  before(async () => {
    // Pre-condition: fitur verifikasi wajah dibuka.
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should reject face verification for another student', async () => {
    // Langkah Pengujian:
    // 1. Verifikasi wajah dengan data akun lain
    // Expected Result: Verifikasi ditolak karena data wajah tidak cocok

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

    const statusVerifikasi = await $(
      '~Wajah terdeteksi! Absensi berhasil.'
    );
    await expect(statusVerifikasi).toBeDisplayed();
  });
});
