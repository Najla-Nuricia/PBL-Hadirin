/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-013
 * Skenario ID : TS-MHS-004
 * Modul / Fitur: Account
 * Judul Test Case: Upload foto profil mahasiswa
 * Tipe Kasus  : Positif
 * Prioritas   : Sedang
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Mahasiswa sudah login dan tersedia foto di file picker.
 * Langkah      : 1. Buka menu akun
 *               2. Tekan foto profil
 *               3. Pilih foto
 * Expected Result: Foto profil berhasil diperbarui
 */

import { browser, expect, $ } from '@wdio/globals';
import { goToStudentTab, mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

async function clickFirstPhotoInPicker(): Promise<void> {
  await browser.pause(2000);

  const { width, height } = await browser.getWindowSize();
  await browser.execute('mobile: clickGesture', {
    x: Math.round(width * (62 / 375)),
    y: Math.round(height * (464 / 812)),
  });
}

async function confirmPhotoSelection(): Promise<void> {
  const nativeDoneButton = $('android=new UiSelector().text("Selesai")');
  if (await nativeDoneButton.isDisplayed().catch(() => false)) {
    await nativeDoneButton.click();
    return;
  }

  const nativeDoneDescription = $(
    'android=new UiSelector().description("Selesai")',
  );
  if (await nativeDoneDescription.isDisplayed().catch(() => false)) {
    await nativeDoneDescription.click();
    return;
  }

  const { width, height } = await browser.getWindowSize();
  await browser.execute('mobile: clickGesture', {
    x: Math.round(width * (300 / 375)),
    y: Math.round(height * (773 / 812)),
  });
}

describe('TC-MHS-013 - Upload foto profil mahasiswa', () => {
  before(async () => {
    // Pre-condition: mahasiswa sudah login.
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should upload a profile photo', async () => {
    // Langkah Pengujian:
    // 1. Buka menu akun
    // 2. Tekan foto profil
    // 3. Pilih foto pertama yang tersedia
    // Expected Result: Foto profil berhasil diperbarui

    await browser.pause(3000);
    await goToStudentTab('Profil');

    await $('~Ubah foto profil').click();

    await clickFirstPhotoInPicker();
    await confirmPhotoSelection();

    const snackbar = $(
      'android=new UiSelector().descriptionContains("Foto profil berhasil diperbarui")',
    );
    await snackbar.waitForDisplayed({
      timeout: 15000,
      timeoutMsg: 'Snackbar foto profil berhasil diperbarui tidak muncul',
    });
    await expect(snackbar).toBeDisplayed();
  });
});
