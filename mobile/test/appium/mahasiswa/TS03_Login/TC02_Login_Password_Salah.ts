/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-009
 * Skenario ID : TS-MHS-003
 * Modul / Fitur: Autentikasi
 * Judul Test Case: Login dengan password salah
 * Tipe Kasus  : Negatif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Akun tersedia.
 * Langkah      : 1. Masukkan password salah
 *               2. Login
 * Expected Result: Login ditolak dan pesan error ditampilkan
 */

import { expect, $ } from '@wdio/globals';
import { openStudentLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-009 - Login dengan password salah', () => {
  before(async () => {
    await openStudentLogin();
  });

  it('should reject login with wrong password', async () => {
    // Langkah Pengujian:
    // 1. Masukkan password salah
    // 2. Login
    //
    // Expected Result: Login ditolak dan pesan error ditampilkan

    const nimField = await $('android=new UiSelector().className("android.widget.EditText").instance(0)');
    const passwordField = await $('android=new UiSelector().className("android.widget.EditText").instance(1)');
    await nimField.click();
    await nimField.setValue(HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim);
    await passwordField.click();
    await passwordField.setValue('password-salah');
    await $('~Masuk').click();

    await expect($('~NIM atau password salah.')).toBeDisplayed();
  });
});
