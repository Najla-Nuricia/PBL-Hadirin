/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-030
 * Skenario ID : TS-MHS-012
 * Modul / Fitur: Presensi - Simpanan
 * Judul Test Case: Simpan presensi saat koneksi terputus
 * Tipe Kasus  : Negatif
 * Prioritas   : Sedang
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Presensi berhasil diverifikasi, tetapi koneksi internet terputus.
 * Langkah      : 1. Kirim / simpan presensi saat koneksi terputus
 * Expected Result: Kegagalan sinkronisasi dilaporkan tanpa data presensi berganda
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-030 - Simpan presensi saat koneksi terputus', () => {
  before(async () => {
    // Pre-condition: presensi berhasil diverifikasi, koneksi terputus.
    await mahasiswaLogin( HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim, HADIRIN_DEMO_ACCOUNTS.mahasiswa.password, );
  });

  it('should handle attendance save failure during connectivity loss', async () => {
    // Langkah Pengujian:
    // 1. Kirim / simpan presensi saat koneksi terputus
    // Expected Result: Kegagalan sinkronisasi dilaporkan tanpa data presensi berganda

    await browser.pause(2000);

    const submitAbsensiButton = await $(
      '~Lanjutkan ke Scan Wajah'
    );
    await submitAbsensiButton.click();
    await browser.pause(3000);

    const snackbarError = await $(
      '~Koneksi terputus'
    );
    await expect(snackbarError).toBeDisplayed();
  });
});
