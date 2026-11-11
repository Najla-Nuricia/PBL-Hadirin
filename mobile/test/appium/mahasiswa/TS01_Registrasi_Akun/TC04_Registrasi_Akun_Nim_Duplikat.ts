/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-004
 * Skenario ID : TS-MHS-001
 * Modul / Fitur: Autentikasi
 * Judul Test Case: Registrasi mahasiswa dengan NIM yang sudah terdaftar
 * Tipe Kasus  : Negatif
 * Prioritas   : Sedang
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Halaman registrasi terbuka; NIM sudah ada di database.
 * Langkah      : 1. Masukkan NIM terdaftar
 *               2. Submit
 * Expected Result: Sistem menolak registrasi dan menampilkan pesan
 */

import { browser, expect, $ } from '@wdio/globals';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';
import {
  fillField,
  openStudentRegistration,
  tapSubmitRegistrasi,
} from '../../src/support/actions';
import { LOCATORS } from '../../src/support/selectors';

describe('TC-MHS-004 - Registrasi mahasiswa dengan NIM sudah terdaftar', () => {
  before(async () => {
    // Pre-condition: halaman registrasi terbuka.
    await browser.pause(2000);
  });

  it('should reject registration when nim already registered', async () => {
    // Langkah Pengujian:
    // 1. Masukkan NIM terdaftar
    // 2. Submit
    //
    // Expected Result: Sistem menolak registrasi dan menampilkan pesan

    await openStudentRegistration();

    await fillField(
      LOCATORS.mahasiswa.register.fullNameField,
      'Mahasiswa Duplikat',
    );
    await fillField(
      LOCATORS.mahasiswa.register.nimField,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
    );
    await fillField(LOCATORS.mahasiswa.register.classField, '3F-TI');
    await fillField(LOCATORS.mahasiswa.register.passwordField, 'najla1234');
    await fillField(
      LOCATORS.mahasiswa.register.confirmPasswordField,
      'najla1234',
    );

    await tapSubmitRegistrasi();

    const snackbar = $(LOCATORS.mahasiswa.register.duplicateNimSnackbar);
    await snackbar.waitForDisplayed({
      timeout: 10000,
      timeoutMsg: 'Snackbar NIM sudah terdaftar tidak muncul',
    });
    await expect(snackbar).toBeDisplayed();
  });
});
