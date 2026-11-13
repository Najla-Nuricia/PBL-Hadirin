/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-DOSEN-043
 * Skenario ID : TS-DOSEN-005
 * Modul / Fitur: Kehadiran
 * Judul Test Case: Melihat mahasiswa yang berhasil presensi
 * Tipe Kasus  : Positif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Dosen)
 * Pre-kondisi  : Terdapat presensi mahasiswa.
 * Langkah      : 1. Buka dashboard kehadiran
 * Expected Result: Nama mahasiswa dan jam presensi ditampilkan
 *
 * Catatan: nama + jam presensi diambil dari
 * lib/data/dosen/lecturer_dummy_data.dart dan dirender oleh
 * StudentAttendanceTile (semantics: "Nama, NIM ..., status ..., jam HH:MM").
 */

import { browser, expect, $ } from '@wdio/globals';
import {
  dosenLogin,
  lecturerStudentTile,
  openLecturerAttendance,
  showLecturerAttendance,
} from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';
import { LOCATORS } from '../../src/support/selectors';

describe('TC-DOSEN-043 - Melihat mahasiswa yang berhasil presensi', () => {
  before(async () => {
    // Pre-condition: dosen sudah login dan sudah ada presensi mahasiswa.
    await dosenLogin(
      HADIRIN_DEMO_ACCOUNTS.dosen.email,
      HADIRIN_DEMO_ACCOUNTS.dosen.password,
    );
  });

  it('should display student names and check-in times', async () => {
    // Langkah Pengujian:
    // 1. Buka dashboard kehadiran lalu tampilkan daftar kehadiran.
    await openLecturerAttendance();
    await showLecturerAttendance();

    // Expected Result: nama mahasiswa dan jam presensi ditampilkan.
    await expect(
      $(lecturerStudentTile('Adi Saputra', '07:58')),
    ).toBeDisplayed();
    await expect(
      $(lecturerStudentTile('Budi Santoso', '08:02')),
    ).toBeDisplayed();

    // Filter status Hadir: hanya mahasiswa yang berhasil presensi.
    await $(LOCATORS.dosen.attendance.statusChip.hadir).click();
    await browser.pause(1000);

    await expect(
      $(lecturerStudentTile('Adi Saputra', '07:58')),
    ).toBeDisplayed();
    // Mahasiswa berstatus Alfa tidak ikut tampil.
    await expect($(lecturerStudentTile('Galih Pratama'))).not.toBeExisting();
  });
});
