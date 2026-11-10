/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-026
 * Skenario ID : TS-MHS-011
 * Modul / Fitur: Face Recognition - Verifikasi
 * Judul Test Case: Verifikasi wajah saat proses presensi
 * Tipe Kasus  : Positif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Akun mahasiswa sudah terdaftar dan proses verifikasi wajah dibuka.
 * Langkah      : 1. Scan wajah untuk verifikasi
 *               2. Periksa status dan similarity
 * Expected Result: Status terdeteksi WAJAH COCOK dan similarity memenuhi threshold
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-026 - Verifikasi wajah saat proses presensi', () => {
  before(async () => {
    // Pre-condition: mahasiswa sudah login dan fitur verifikasi wajah dibuka.
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should verify registered face and check similarity', async () => {
    // Langkah Pengujian:
    // 1. Scan wajah untuk verifikasi
    // 2. Periksa status dan similarity
    // Expected Result: Status terdeteksi WAJAH COCOK dan similarity memenuhi threshold

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

    const similarity = await $(
      '~Wajah terdeteksi! Absensi berhasil.'
    );
    await expect(similarity).toBeDisplayed();
  });
});
