/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-015
 * Skenario ID : TS-MHS-007
 * Modul / Fitur: Presensi
 * Judul Test Case: Presensi pada waktu kelas yang sesuai
 * Tipe Kasus  : Positif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Jadwal sedang berlangsung.
 * Langkah      : 1. Buka fitur presensi
 * Expected Result: Fitur presensi dapat digunakan
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-015 - Presensi pada waktu kelas yang sesuai', () => {
  before(async () => {
    // Pre-condition: mahasiswa sudah login dan jadwal sedang berlangsung.
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should allow attendance during scheduled class time', async () => {
    // Langkah Pengujian:
    // 1. Buka fitur presensi
    //
    // Expected Result: Fitur presensi dapat digunakan

    await browser.pause(3000);

    const absensiMenu = await $(
      '~Absensi'
    );
    await absensiMenu.click();
    await browser.pause(2000);

    const fiturAbsensi = await $(
      '~Scan QR'
    );
    await expect(fiturAbsensi).toBeDisplayed();
  });
});
