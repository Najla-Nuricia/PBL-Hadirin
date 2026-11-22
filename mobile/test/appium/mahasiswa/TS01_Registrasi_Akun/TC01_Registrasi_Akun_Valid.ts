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
import {fillField, openStudentRegistration,tapSubmitRegistrasi} from '../../src/support/actions';
import { LOCATORS } from '../../src/support/selectors';


describe('TC-MHS-001 - Registrasi mahasiswa dengan data valid', () => {
  before(async () => {
    // Pre-condition: aplikasi terpasang.
    await browser.pause(2000);
  });

  it('should register mahasiswa with valid data', async () => {
    // Langkah Pengujian:
    // 1. Buka registrasi
    // 2. Isi nama, NIM, kelas, kata sandi, dan konfirmasi kata sandi
    // 3. Submit
    //
    // Data Uji:
    // - Nama: Najla Nuricia
    // - NIM: 244107020091
    // - Kelas: 3F-TI

    await openStudentRegistration();

    await fillField(
      LOCATORS.mahasiswa.register.fullNameField,
      'Najla Nuricia',
    );
    await fillField(
      LOCATORS.mahasiswa.register.nimField,
      '244107020091',
    );
    await fillField(
      LOCATORS.mahasiswa.register.classField,
      '3F-TI',
    );
    await fillField(
      LOCATORS.mahasiswa.register.passwordField,
      'najla1234',
    );
    await fillField(
      LOCATORS.mahasiswa.register.confirmPasswordField,
      'najla1234',
    );

    await tapSubmitRegistrasi();
    await browser.pause(3000);

    // Akun dibuat setelah lima sampel wajah selesai; tahap ini memastikan
    // data registrasi valid dan berhasil diteruskan ke scan wajah.
    const scanWajah = await $(
    'android=new UiSelector().descriptionMatches("(?i).*scan wajah.*")',
    );
    await scanWajah.waitForDisplayed({ timeout: 15000 });
    await expect(scanWajah).toBeDisplayed();
  });
});
