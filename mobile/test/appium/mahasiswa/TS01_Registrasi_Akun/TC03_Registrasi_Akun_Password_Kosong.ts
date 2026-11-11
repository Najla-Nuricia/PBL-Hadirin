/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-003
 * Skenario ID : TS-MHS-001
 * Modul / Fitur: Autentikasi
 * Judul Test Case: Registrasi mahasiswa dengan password kosong
 * Tipe Kasus  : Negatif
 * Prioritas   : Sedang
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Halaman registrasi terbuka.
 * Langkah      : 1. Kosongkan password
 *               2. Submit
 * Expected Result: Sistem menampilkan validasi password wajib diisi
 */

import { browser, expect, $ } from '@wdio/globals';
import {
  fillField,
  openStudentRegistration,
  tapSubmitRegistrasi,
} from '../../src/support/actions';
import { LOCATORS } from '../../src/support/selectors';

describe('TC-MHS-003 - Registrasi mahasiswa dengan password kosong', () => {
  before(async () => {
    // Pre-condition: halaman registrasi terbuka.
    await browser.pause(2000);
  });

  it('should show validation when password is empty', async () => {
    // Langkah Pengujian:
    // 1. Kosongkan password
    // 2. Submit
    //
    // Expected Result: Sistem menampilkan validasi password wajib diisi

    await openStudentRegistration();

    await fillField(
      LOCATORS.mahasiswa.register.fullNameField,
      'Najla Nuricia',
    );
    await fillField(LOCATORS.mahasiswa.register.nimField, '244107020091');
    await fillField(LOCATORS.mahasiswa.register.classField, '3F-TI');
    await fillField(LOCATORS.mahasiswa.register.passwordField, '');
    await fillField(
      LOCATORS.mahasiswa.register.confirmPasswordField,
      'najla1234',
    );

    await tapSubmitRegistrasi();
    await browser.pause(3000);

    // Assertion: validasi password wajib diisi ditampilkan.
    await expect($('~Kata sandi wajib diisi.')).toBeDisplayed();
  });
});
