/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-031
 * Skenario ID : TS-MHS-013
 * Modul / Fitur: Riwayat Presensi
 * Judul Test Case: Melihat riwayat presensi
 * Tipe Kasus  : Positif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Mahasiswa sudah login.
 * Langkah      : 1. Buka menu riwayat
 * Expected Result: Riwayat kehadiran ditampilkan
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-031 - Melihat riwayat presensi', () => {
  before(async () => {
    // Pre-condition: mahasiswa sudah login.
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should display attendance history', async () => {
    // Langkah Pengujian:
    // 1. Buka menu riwayat
    // Expected Result: Riwayat kehadiran ditampilkan

    await browser.pause(3000);

    const riwayatMenu = await $(
      '~Riwayat'
    );
    await riwayatMenu.click();
    await browser.pause(2000);

    const daftarRiwayat = await $(
      '~Hadir'
    );
    await expect(daftarRiwayat).toBeDisplayed();
  });
});
