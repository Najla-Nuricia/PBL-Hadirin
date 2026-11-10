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
import { openStudentRegistration } from '../../src/support/actions';
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

    await $(LOCATORS.mahasiswa.register.fullNameField).setValue('Mahasiswa Duplikat');
    const nimField = await $(LOCATORS.mahasiswa.register.nimField);
    await nimField.setValue(HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim);
    await $(LOCATORS.mahasiswa.register.classField).setValue('3F-TI');
    await $(LOCATORS.mahasiswa.register.passwordField).setValue('najla1234');
    await $(LOCATORS.mahasiswa.register.confirmPasswordField).setValue('najla1234');

    const submitButton = await $(LOCATORS.mahasiswa.register.submitButton);
    await submitButton.click();
    await browser.pause(3000);

    // Assertion: registrasi ditolak dan pesan NIM sudah terdaftar ditampilkan.
    await expect($(LOCATORS.mahasiswa.register.duplicateNimSnackbar)).toBeDisplayed();
  });
});
