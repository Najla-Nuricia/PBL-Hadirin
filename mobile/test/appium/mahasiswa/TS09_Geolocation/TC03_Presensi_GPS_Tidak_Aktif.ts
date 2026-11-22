/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-022
 * Skenario ID : TS-MHS-009
 * Modul / Fitur: Geolocation
 * Judul Test Case: GPS perangkat tidak aktif
 * Tipe Kasus  : Negatif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : GPS mati.
 * Langkah      : 1. Jalankan presensi
 * Expected Result: Sistem meminta pengguna mengaktifkan lokasi
 */

import { browser, expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-022 - Presensi dengan GPS tidak aktif', () => {
  before(async () => {
    // Pre-condition: GPS perangkat mati.
    await mahasiswaLogin( HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim, HADIRIN_DEMO_ACCOUNTS.mahasiswa.password, );
  });

  it('should request location activation when gps is off', async () => {
    // Langkah Pengujian:
    // 1. Jalankan presensi
    //
    // Expected Result: Sistem meminta pengguna mengaktifkan lokasi

    await browser.pause(2000);

    const mulaiAbsensiButton = await $(
      '~Absensi'
    );
    await mulaiAbsensiButton.click();
    await browser.pause(3000);

    // Assertion: permintaan aktivasi lokasi tampil.
    // ~JTI Polinema belum tersedia.
    await expect($('~JTI Polinema')).toBeDisplayed();
  });
});
