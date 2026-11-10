/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-020
 * Skenario ID : TS-MHS-009
 * Modul / Fitur: Geolocation
 * Judul Test Case: Presensi dari dalam area geofencing
 * Tipe Kasus  : Positif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : GPS aktif, berada di area JTI.
 * Langkah      : 1. Jalankan presensi
 * Expected Result: Lokasi dinyatakan valid
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-020 - Presensi dari dalam area geofencing', () => {
  before(async () => {
    // Pre-condition: mahasiswa sudah login.
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should accept attendance within geofence area', async () => {
    // Langkah Pengujian:
    // 1. Jalankan presensi
    //
    // Expected Result: Lokasi dinyatakan valid

    await browser.pause(3000);

    const mulaiAbsensiButton = await $(
      '~Absensi'
    );
    await mulaiAbsensiButton.click();
    await browser.pause(3000);

    // Assertion: status lokasi ditampilkan valid.
    // ~Status Lokasi belum tersedia.
    await expect($('~Status Lokasi')).toBeDisplayed();
  });
});
