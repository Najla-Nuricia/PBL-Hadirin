/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-014
 * Skenario ID : TS-MHS-006
 * Modul / Fitur: Reminder
 * Judul Test Case: Alarm 30 menit sebelum kelas
 * Tipe Kasus  : Positif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Jadwal kelas tersedia.
 * Langkah      : 1. Tunggu hingga 30 menit sebelum kelas
 * Expected Result: Alarm / pengingat muncul
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-014 - Alarm 30 menit sebelum kelas', () => {
  before(async () => {
    // Pre-condition: jadwal kelas tersedia.
    await mahasiswaLogin( HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim, HADIRIN_DEMO_ACCOUNTS.mahasiswa.password, );
  });

  it('should show reminder before class starts', async () => {
    // Langkah Pengujian:
    // 1. Tunggu hingga 30 menit sebelum kelas
    //
    // Expected Result: Alarm / pengingat muncul

    await browser.pause(5000);

    const notifikasi = await $(
      '~Pengingat kelas'
    );
    await expect(notifikasi).toBeDisplayed();
  });
});
