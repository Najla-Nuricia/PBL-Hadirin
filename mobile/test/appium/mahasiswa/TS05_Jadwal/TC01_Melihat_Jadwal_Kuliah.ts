/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-013
 * Skenario ID : TS-MHS-005
 * Modul / Fitur: Jadwal
 * Judul Test Case: Melihat jadwal kuliah
 * Tipe Kasus  : Positif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Mahasiswa sudah login.
 * Langkah      : 1. Buka menu jadwal
 * Expected Result: Jadwal kuliah ditampilkan sesuai kelas
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-013 - Melihat jadwal kuliah mahasiswa', () => {
  before(async () => {
    // Pre-condition: mahasiswa sudah login.
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should display student schedule', async () => {
    // Langkah Pengujian:
    // 1. Buka menu jadwal
    //
    // Expected Result: Jadwal kuliah ditampilkan sesuai kelas

    await browser.pause(3000);

    const jadwalMenu = await $(
      '~Jadwal Kelas'
    );
    await jadwalMenu.click();
    await browser.pause(2000);

    const daftarJadwal = await $(
      '~Pemrograman Web'
    );
    await expect(daftarJadwal).toBeDisplayed();
  });
});
