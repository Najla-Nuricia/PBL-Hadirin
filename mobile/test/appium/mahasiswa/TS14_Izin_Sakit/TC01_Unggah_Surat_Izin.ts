/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-033
 * Skenario ID : TS-MHS-014
 * Modul / Fitur: Izin / Sakit
 * Judul Test Case: Unggah surat izin / sakit
 * Tipe Kasus  : Positif
 * Prioritas   : Sedang
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Mahasiswa sudah login.
 * Langkah      : 1. Buka menu surat / permohonan
 *               2. Unggah file surat izin / sakit
 *               3. Submit
 * Expected Result: Permohonan berhasil dikirim
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-033 - Unggah surat izin / sakit', () => {
  before(async () => {
    // Pre-condition: mahasiswa sudah login.
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should submit letter of absence request', async () => {
    // Langkah Pengujian:
    // 1. Buka menu surat / permohonan
    // 2. Unggah file surat izin / sakit
    // 3. Submit
    // Expected Result: Permohonan berhasil dikirim

    await browser.pause(3000);

    const menuSurat = await $(
      '~Surat'
    );
    await menuSurat.click();
    await browser.pause(2000);

    const unggahSuratButton = await $(
      '~Kirim File'
    );
    await unggahSuratButton.click();
    await browser.pause(3000);

    const submitButton = await $(
      '~Kirim Surat'
    );
    await submitButton.click();
    await browser.pause(3000);

    // Assertion: permohonan izin/sakit berhasil dikirim.
    // ~Pengajuan surat berhasil dikirim! belum tersedia.
    await expect($('~Pengajuan surat berhasil dikirim!')).toBeDisplayed();
  });
});
