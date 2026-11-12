/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-002
 * Skenario ID : TS-MHS-001
 * Modul / Fitur: Autentikasi
 * Judul Test Case: Registrasi mahasiswa dengan NIM kosong
 * Tipe Kasus  : Negatif
 * Prioritas   : Sedang
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Halaman registrasi terbuka.
 * Langkah      : 1. Kosongkan NIM
 *               2. Submit
 * Expected Result: Sistem menampilkan validasi NIM wajib diisi
 */

import { browser, expect, $ } from '@wdio/globals';
import {
  fillField,
  openStudentRegistration,
  tapSubmitRegistrasi,
} from '../../src/support/actions';
import { LOCATORS } from '../../src/support/selectors';

describe('TC-MHS-002 - Registrasi mahasiswa dengan NIM kosong', () => {
  before(async () => {
    // Pre-condition: halaman registrasi terbuka.
    await browser.pause(2000);
  });

  it('should show validation when nim is empty', async () => {
    // Langkah Pengujian:
    // 1. Kosongkan NIM
    // 2. Submit
    //
    // Expected Result: Sistem menampilkan validasi NIM wajib diisi

    await openStudentRegistration();

    await fillField(
      LOCATORS.mahasiswa.register.fullNameField,
      'Najla Nuricia',
    );
    await fillField(LOCATORS.mahasiswa.register.nimField, '');
    await fillField(LOCATORS.mahasiswa.register.classField, '3F-TI');
    await fillField(LOCATORS.mahasiswa.register.passwordField, 'najla1234');
    await fillField(
      LOCATORS.mahasiswa.register.confirmPasswordField,
      'najla1234',
    );

    await tapSubmitRegistrasi();
    await browser.pause(3000);

    // Assertion: validasi NIM wajib diisi ditampilkan.
    await expect($('~NIM wajib diisi.')).toBeDisplayed();
  });
});
