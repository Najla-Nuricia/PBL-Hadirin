/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-013
 * Skenario ID  : TS-MHS-017
 * Judul Test Case: Ubah kata sandi setelah login
 * Tipe Kasus   : Positif
 * Prioritas    : Tinggi
 */

import { browser, expect, $ } from '@wdio/globals';
import { goToStudentTab, mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-013 - Ubah kata sandi setelah login', () => {
  before(async () => {
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should update the student password successfully', async () => {
    await goToStudentTab('Profil');
    await $('~Ubah Kata Sandi').click();

    const currentPasswordField = await $(
      'android=new UiSelector().className("android.widget.EditText").instance(0)',
    );
    const newPasswordField = await $(
      'android=new UiSelector().className("android.widget.EditText").instance(1)',
    );
    const confirmationField = await $(
      'android=new UiSelector().className("android.widget.EditText").instance(2)',
    );

    await currentPasswordField.click();
    await currentPasswordField.setValue(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
    await newPasswordField.click();
    await newPasswordField.setValue('mahasiswa456');
    await confirmationField.click();
    await confirmationField.setValue('mahasiswa456');
    await $('~Simpan').click();

    const snackbar = $('//*[contains(@content-desc,"Kata sandi berhasil diubah")]');
    await snackbar.waitForDisplayed({
      timeout: 15000,
      timeoutMsg: 'Snackbar kata sandi berhasil diubah tidak muncul',
    });
    await expect(snackbar).toBeDisplayed();
  });
});
