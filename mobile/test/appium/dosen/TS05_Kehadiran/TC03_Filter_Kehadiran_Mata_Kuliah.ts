/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-DOSEN-042
 * Skenario ID : TS-DOSEN-005
 * Modul / Fitur: Kehadiran
 * Judul Test Case: Filter berdasarkan mata kuliah
 * Tipe Kasus  : Positif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Dosen)
 * Pre-kondisi  : Dosen sudah login.
 * Langkah      : 1. Pilih mata kuliah
 *                2. Lihat data
 * Expected Result: Data kehadiran sesuai mata kuliah ditampilkan
 *
 * Catatan: opsi mata kuliah berasal dari
 * lib/data/dosen/presensi_options.dart. Nilai pilihan tercermin pada
 * "Ringkasan Pilihan" di halaman Cek Daftar Presensi.
 */

import { expect, $ } from '@wdio/globals';
import {
  dosenLogin,
  lecturerStudentTile,
  openLecturerAttendance,
  selectPresensiValue,
  showLecturerAttendance,
} from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';
import { LOCATORS } from '../../src/support/selectors';

describe('TC-DOSEN-042 - Filter kehadiran berdasarkan mata kuliah', () => {
  before(async () => {
    // Pre-condition: dosen sudah login.
    await dosenLogin(
      HADIRIN_DEMO_ACCOUNTS.dosen.email,
      HADIRIN_DEMO_ACCOUNTS.dosen.password,
    );
  });

  it('should display attendance data for the selected course', async () => {
    // Langkah Pengujian:
    // 1. Pilih mata kuliah (Basis Data -> Pemrograman Mobile)
    await openLecturerAttendance();
    await selectPresensiValue('Basis Data', 'Pemrograman Mobile');

    // Assertion: mata kuliah pilihan tampil di halaman filter.
    await expect(
      $(LOCATORS.dosen.attendance.option('Pemrograman Mobile')),
    ).toBeDisplayed();

    // 2. Lihat data
    await showLecturerAttendance();

    // Expected Result: daftar kehadiran ditampilkan.
    await expect($(LOCATORS.dosen.attendance.listTitle)).toBeDisplayed();
    await expect($(LOCATORS.dosen.attendance.summary)).toBeDisplayed();
    await expect($(lecturerStudentTile('Adi Saputra'))).toBeDisplayed();
  });
});
