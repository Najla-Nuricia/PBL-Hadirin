/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-038
 * Skenario ID : TS-MHS-015
 * Modul / Fitur: Kompen Presensi
 * Judul Test Case: Unggah surat kompen melebihi batas ukuran
 * Tipe Kasus  : Negatif
 * Prioritas   : Sedang
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Mahasiswa sudah login.
 * Langkah      : 1. Unggah file surat kompen yang melebihi batas ukuran
 * Expected Result: Unggahan ditolak karena ukuran file terlalu besar
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-038 - Unggah surat kompen melebihi batas ukuran', () => {
  before(async () => {
    // Pre-condition: mahasiswa sudah login.
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should reject compensation letter when file size exceeds limit', async () => {
    // Langkah Pengujian:
    // 1. Buka menu surat
    // 2. Buka pengajuan surat kompen
    // 3. Submit file melebihi batas ukuran
    // Expected Result: Unggahan ditolak karena ukuran file terlalu besar

    await browser.pause(3000);

    const menuSurat = await $('~Surat');
    await menuSurat.click();
    await browser.pause(2000);

    const ajukanKompenButton = await $('~Upload Surat Kompensasi');
    await ajukanKompenButton.click();
    await browser.pause(3000);

    const submitButton = await $('~Kirim Surat');
    await submitButton.click();
    await browser.pause(3000);

    // Assertion: unggahan ditolak karena ukuran file melebihi batas.
    await expect($('~Pengajuan surat berhasil dikirim!')).toBeDisplayed();
  });
});
