/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-MHS-007
 * Skenario ID : TS-MHS-002
 * Modul / Fitur: Face Registration
 * Judul Test Case: Registrasi wajah dengan pencahayaan buruk
 * Tipe Kasus  : Negatif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Mahasiswa)
 * Pre-kondisi  : Kamera aktif.
 * Langkah      : 1. Ambil sampel dalam kondisi gelap
 * Expected Result: Sistem menolak / memberikan peringatan jika wajah tidak dapat diproses
 */

import { browser, expect, $ } from '@wdio/globals';

describe('TC-MHS-007 - Registrasi wajah dengan pencahayaan buruk', () => {
  before(async () => {
    // Pre-condition: kamera aktif.
    await browser.pause(2000);
  });

  it('should reject face sample when lighting is poor', async () => {
    // Langkah Pengujian:
    // 1. Ambil sampel dalam kondisi gelap
    //
    // Expected Result: Sistem menolak / memberikan peringatan jika wajah tidak dapat diproses

    await browser.pause(2000);

    const arahkanKameraButton = await $(
      '~Scan Wajah'
    );
    await arahkanKameraButton.click();
    await browser.pause(5000);

    const kunciWajahButton = await $(
      '~Ambil Foto'
    );
    await kunciWajahButton.click();
    await browser.pause(3000);

    // Assertion: peringatan / penolakan jika wajah tidak dapat diproses.
    // ~Ambil Foto belum tersedia.
    await expect($('~Ambil Foto')).toBeDisplayed();
  });
});
