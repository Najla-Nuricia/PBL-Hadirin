/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-036
 * Skenario ID : TS-MHS-015
 * Modul / Fitur: Kompen Presensi
 * Judul Test Case: Ajukan surat kompen presensi
 * Tipe Kasus  : Positif
 * Prioritas   : Sedang
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Mahasiswa sudah login dan presensi belum dikompensasi.
 * Langkah      : 1. Buka menu kompen
 *               2. Ajukan surat kompen presensi
 *               3. Submit
 * Expected Result: Permohonan kompen berhasil dikirim
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-036 - Ajukan surat kompen presensi', () => {
  before(async () => {
    // Pre-condition: mahasiswa sudah login.
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should submit attendance compensation letter', async () => {
    // Langkah Pengujian:
    // 1. Buka menu kompen
    // 2. Ajukan surat kompen presensi
    // 3. Submit
    // Expected Result: Permohonan kompen berhasil dikirim

    await browser.pause(3000);

    const menuKompen = await $(
      '~Surat'
    );
    await menuKompen.click();
    await browser.pause(2000);

    const ajukanKompenButton = await $(
      '~Upload Surat Kompensasi'
    );
    await ajukanKompenButton.click();
    await browser.pause(3000);

    const submitButton = await $(
      '~Kirim Surat'
    );
    await submitButton.click();
    await browser.pause(3000);

    // Assertion: permohonan kompen berhasil dikirim.
    // ~Pengajuan surat berhasil dikirim! belum tersedia.
    await expect($('~Pengajuan surat berhasil dikirim!')).toBeDisplayed();
  });
});
