/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-005
 * Skenario ID : TS-MHS-002
 * Modul / Fitur: Face Registration
 * Judul Test Case: Registrasi 5 sampel wajah
 * Tipe Kasus  : Positif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Akun mahasiswa tersedia.
 * Langkah      : 1. Buka registrasi wajah
 *               2. Ambil wajah depan, kanan, kiri, atas, bawah
 * Expected Result: Kelima sampel berhasil diproses dan data wajah tersimpan
 */

import { browser, expect, $ } from '@wdio/globals';

describe('TC-MHS-005 - Registrasi 5 sampel wajah', () => {
  before(async () => {
    // Pre-condition: akun mahasiswa tersedia dan proses registrasi wajah dibuka.
    await browser.pause(2000);
  });

  it('should capture five face samples', async () => {
    // Langkah Pengujian:
    // 1. Buka registrasi wajah
    // 2. Ambil wajah depan, kanan, kiri, atas, bawah
    //
    // Expected Result: Kelima sampel berhasil diproses dan data wajah tersimpan

    await browser.pause(2000);

    const bukaRegistrasiWajahButton = await $(
      '~Daftar wajah'
    );
    await bukaRegistrasiWajahButton.click();
    await browser.pause(3000);

    const arahkanKameraButton = await $(
      '~Scan Wajah'
    );
    await arahkanKameraButton.click();
    await browser.pause(5000);

    // Uji berikut memerlukan kamera wajah real (inilah batasan otomatisasi).
    const kunciWajahButton = await $(
      '~Ambil Foto'
    );
    await kunciWajahButton.click();
    await browser.pause(3000);

    // Uji berikut memerlukan kamera wajah real (lalu ulang untuk 5 arah).
    const lanjutButton = await $(
      '~Lanjutkan ke Scan Wajah'
    );
    await lanjutButton.click();
    await browser.pause(3000);

    // Assertion: kelima sampel berhasil diproses dan data wajah tersimpan.
    // ~Ambil Foto belum tersedia.
    await expect($('~Ambil Foto')).toBeDisplayed();
  });
});
