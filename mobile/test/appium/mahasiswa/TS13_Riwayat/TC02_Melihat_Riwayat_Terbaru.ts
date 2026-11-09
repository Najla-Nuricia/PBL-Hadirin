/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-032
 * Skenario ID : TS-MHS-013
 * Modul / Fitur: Riwayat Presensi
 * Judul Test Case: Melihat riwayat presensi terbaru
 * Tipe Kasus  : Positif
 * Prioritas   : Sedang
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Riwayat sudah ada minimal satu entri.
 * Langkah      : 1. Buka menu riwayat
 *               2. Pastikan entri terbaru ditampilkan di urutan atas
 * Expected Result: Riwayat terbaru ditampilkan sesuai urutan waktu
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-032 - Melihat riwayat presensi terbaru', () => {
  before(async () => {
    // Pre-condition: riwayat sudah ada minimal satu entri.
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should display most recent attendance history entry', async () => {
    // Langkah Pengujian:
    // 1. Buka menu riwayat
    // 2. Pastikan entri terbaru ditampilkan di urutan atas
    // Expected Result: Riwayat terbaru ditampilkan sesuai urutan waktu

    await browser.pause(3000);

    const riwayatMenu = await $(
      '~Riwayat'
    );
    await riwayatMenu.click();
    await browser.pause(2000);

    const entriTerbaru = await $(
      '~Pemrograman Web'
    );
    await expect(entriTerbaru).toBeDisplayed();
  });
});
