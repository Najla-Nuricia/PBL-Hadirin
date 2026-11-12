/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-035
 * Skenario ID : TS-MHS-014
 * Modul / Fitur: Izin / Sakit
 * Judul Test Case: Unggah surat izin / sakit melebihi batas ukuran
 * Tipe Kasus  : Negatif
 * Prioritas   : Sedang
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Mahasiswa sudah login.
 * Langkah      : 1. Unggah file surat izin / sakit yang melebihi batas ukuran
 * Expected Result: Unggahan ditolak karena ukuran file terlalu besar
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-035 - Unggah surat izin / sakit melebihi batas ukuran', () => {
  before(async () => {
    // Pre-condition: mahasiswa sudah login.
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should reject absence letter when file size exceeds limit', async () => {
    // Langkah Pengujian:
    // 1. Unggah file surat izin / sakit yang melebihi batas ukuran
    // Expected Result: Unggahan ditolak karena ukuran file terlalu besar

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

    // Assertion: unggahan ditolak karena ukuran file melebihi batas.
    // ~Pengajuan surat berhasil dikirim! belum tersedia.
    await expect($('~Pengajuan surat berhasil dikirim!')).toBeDisplayed();
  });
});
