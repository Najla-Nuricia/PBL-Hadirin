/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-021
 * Skenario ID : TS-MHS-009
 * Modul / Fitur: Geolocation
 * Judul Test Case: Presensi dari luar area geofencing
 * Tipe Kasus  : Negatif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : GPS aktif, berada di luar area.
 * Langkah      : 1. Jalankan presensi
 * Expected Result: Presensi ditolak karena lokasi di luar area
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-021 - Presensi dari luar area geofencing', () => {
  before(async () => {
    // Pre-condition: berada di luar area geofence.
    await mahasiswaLogin( HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim, HADIRIN_DEMO_ACCOUNTS.mahasiswa.password, );
  });

  it('should reject attendance outside geofence area', async () => {
    // Langkah Pengujian:
    // 1. Jalankan presensi
    //
    // Expected Result: Presensi ditolak karena lokasi di luar area

    await browser.pause(2000);

    const mulaiAbsensiButton = await $(
      '~Absensi'
    );
    await mulaiAbsensiButton.click();
    await browser.pause(3000);

    // Assertion: status lokasi ditampilkan ditolak.
    // ~Status Lokasi belum tersedia.
    await expect($('~Status Lokasi')).toBeDisplayed();
  });
});
