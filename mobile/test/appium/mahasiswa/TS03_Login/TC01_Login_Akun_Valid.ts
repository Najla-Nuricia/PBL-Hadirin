/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-008
 * Skenario ID : TS-MHS-003
 * Modul / Fitur: Autentikasi
 * Judul Test Case: Login dengan akun valid
 * Tipe Kasus  : Positif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Akun telah terdaftar.
 * Langkah      : 1. Masukkan username/NIM dan password valid
 *               2. Login
 * Expected Result: Pengguna berhasil masuk ke dashboard
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-008 - Login dengan akun valid', () => {
  before(async () => {
    // Pre-condition: akun mahasiswa terdaftar.
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should login with valid account', async () => {
    // Langkah Pengujian:
    // 1. Masukkan NIM dan password valid
    // 2. Login
    //
    // Expected Result: Pengguna berhasil masuk ke dashboard

    await browser.pause(3000);

    // Assertion: dashboard mahasiswa tampil setelah login sukses.
    await expect($('~Beranda')).toBeDisplayed();
  });
});
