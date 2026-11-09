/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-012
 * Skenario ID : TS-MHS-004
 * Modul / Fitur: Account
 * Judul Test Case: Update informasi akun
 * Tipe Kasus  : Positif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Mahasiswa sudah login.
 * Langkah      : 1. Ubah informasi
 *               2. Simpan
 * Expected Result: Informasi berhasil diperbarui
 */

import { browser, expect, $ } from '@wdio/globals';
import { goToStudentTab, mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-012 - Update informasi akun mahasiswa', () => {
  before(async () => {
    // Pre-condition: mahasiswa sudah login.
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should update account information', async () => {
    // Langkah Pengujian:
    // 1. Ubah informasi
    // 2. Simpan
    //
    // Expected Result: Informasi berhasil diperbarui

    await browser.pause(3000);

    await goToStudentTab('Profil');
    await $('~Ubah Profil').click();

    const nameField = await $(
      'android=new UiSelector().className("android.widget.EditText").instance(0)',
    );
    const phoneField = await $(
      'android=new UiSelector().className("android.widget.EditText").instance(2)',
    );
    const emailField = await $(
      'android=new UiSelector().className("android.widget.EditText").instance(3)',
    );

    await nameField.clearValue();
    await nameField.setValue('Najla Nuricia');
    await phoneField.clearValue();
    await phoneField.setValue('08570000000');
    await emailField.clearValue();
    await emailField.setValue('najla@email.com');

    await $('~Simpan').click();

    await expect(
      $('android=new UiSelector().text("Najla Nuricia")'),
    ).toBeDisplayed();
    await expect(
      $('android=new UiSelector().text("08570000000")'),
    ).toBeDisplayed();
    await expect(
      $('android=new UiSelector().text("najla@email.com")'),
    ).toBeDisplayed();
  });
});
