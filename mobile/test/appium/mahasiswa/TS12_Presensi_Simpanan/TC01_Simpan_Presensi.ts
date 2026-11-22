/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-029
 * Skenario ID : TS-MHS-012
 * Modul / Fitur: Presensi - Simpanan
 * Judul Test Case: Simpan presensi yang berhasil diverifikasi
 * Tipe Kasus  : Positif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Presensi berhasil diverifikasi.
 * Langkah      : 1. Submit presensi setelah verifikasi berhasil
 * Expected Result: Presensi tersimpan pada riwayat kehadiran
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-029 - Simpan presensi yang berhasil diverifikasi', () => {
  before(async () => {
    // Pre-condition: presensi berhasil diverifikasi.
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should save verified attendance', async () => {
    // Langkah Pengujian:
    // 1. Submit presensi setelah verifikasi berhasil
    // Expected Result: Presensi tersimpan pada riwayat kehadiran

    await browser.pause(3000);

    const submitAbsensiButton = await $(
      '~Lanjutkan ke Scan Wajah'
    );
    await submitAbsensiButton.click();
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
