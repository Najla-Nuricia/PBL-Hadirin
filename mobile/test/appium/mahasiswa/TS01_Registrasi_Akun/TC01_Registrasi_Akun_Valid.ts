/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-001
 * Skenario ID : TS-MHS-001
 * Modul / Fitur: Autentikasi
 * Judul Test Case: Registrasi mahasiswa dengan data valid
 * Tipe Kasus  : Positif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Aplikasi terpasang.
 * Langkah      : 1. Buka registrasi
 *               2. Isi nama, NIM, kelas
 *               3. Submit
 * Data Uji    : Nama : Najla Nuricia, NIM : 244107020091
 * Expected Result: Akun berhasil dibuat
 */

import { browser, expect, $ } from '@wdio/globals';

describe('TC-MHS-001 - Registrasi mahasiswa dengan data valid', () => {
  before(async () => {
    // Pre-condition: aplikasi terpasang dan halaman registrasi terbuka.
    await browser.pause(2000);
  });

  it('should register mahasiswa with valid data', async () => {
    // Langkah Pengujian:
    // 1. Buka registrasi
    // 2. Isi nama, NIM, kelas
    // 3. Submit
    //
    // Data Uji:
    // - Nama: Najla Nuricia
    // - NIM: 244107020091
    // - Kelas: 3F-TI

    await browser.pause(2000);

    const bukaRegistrasiButton = await $(
      '~Daftar'
    );
    await bukaRegistrasiButton.click();
    await browser.pause(2000);

    const namaLengkapField = await $(
      'android=new UiSelector().className("android.widget.EditText").instance(0)'
    );
    await namaLengkapField.setValue('Najla Nuricia');

    const nimField = await $(
      'android=new UiSelector().className("android.widget.EditText").instance(1)'
    );
    await nimField.setValue('244107020091');

    const kelasField = await $(
      'android=new UiSelector().className("android.widget.EditText").instance(2)'
    );
    await kelasField.setValue('3F-TI');

    const submitButton = await $(
      '~Lanjut ke Scan Wajah →'
    );
    await submitButton.click();
    await browser.pause(3000);

    // Assertion: akun berhasil dibuat.
    // ~Registrasi berhasil. Silakan login dengan NIM kamu. belum tersedia.
    await expect($('~Registrasi berhasil. Silakan login dengan NIM kamu.')).toBeDisplayed();
  });
});
