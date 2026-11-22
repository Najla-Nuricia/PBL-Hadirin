/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-DOSEN-041
 * Skenario ID : TS-DOSEN-005
 * Modul / Fitur: Kehadiran
 * Judul Test Case: Filter berdasarkan kelas
 * Tipe Kasus  : Positif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Dosen)
 * Pre-kondisi  : Dosen sudah login.
 * Langkah      : 1. Pilih kelas
 *                2. Lihat data
 * Expected Result: Data mahasiswa sesuai kelas ditampilkan
 *
 * Catatan: opsi kelas berasal dari
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

describe('TC-DOSEN-041 - Filter kehadiran berdasarkan kelas', () => {
  before(async () => {
    // Pre-condition: dosen sudah login.
    await dosenLogin(
      HADIRIN_DEMO_ACCOUNTS.dosen.email,
      HADIRIN_DEMO_ACCOUNTS.dosen.password,
    );
  });

  it('should display students for the selected class', async () => {
    // Langkah Pengujian:
    // 1. Pilih kelas (TI-3A -> TI-3B)
    await openLecturerAttendance();
    await selectPresensiValue('TI-3A', 'TI-3B');

    // Assertion: kelas pilihan tampil di halaman filter.
    await expect(
      $(LOCATORS.dosen.attendance.option('TI-3B')),
    ).toBeDisplayed();

    // 2. Lihat data
    await showLecturerAttendance();

    // Expected Result: daftar mahasiswa ditampilkan.
    await expect($(LOCATORS.dosen.attendance.listTitle)).toBeDisplayed();
    await expect($(LOCATORS.dosen.attendance.summary)).toBeDisplayed();
    await expect($(lecturerStudentTile('Adi Saputra'))).toBeDisplayed();
  });
});
