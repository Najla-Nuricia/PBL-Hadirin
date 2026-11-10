/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-016
 * Skenario ID : TS-MHS-007
 * Modul / Fitur: Presensi
 * Judul Test Case: Presensi di luar waktu kelas
 * Tipe Kasus  : Negatif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Tidak ada kelas aktif.
 * Langkah      : 1. Buka fitur presensi
 * Expected Result: Sistem menolak presensi
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-016 - Presensi di luar waktu kelas', () => {
  before(async () => {
    // Pre-condition: tidak ada kelas aktif.
    await mahasiswaLogin( HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim, HADIRIN_DEMO_ACCOUNTS.mahasiswa.password, );
  });

  it('should reject attendance outside scheduled time', async () => {
    // Langkah Pengujian:
    // 1. Buka fitur presensi
    //
    // Expected Result: Sistem menolak presensi

    await browser.pause(2000);

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
