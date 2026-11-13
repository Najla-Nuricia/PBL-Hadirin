/**
 * Hadirin QA - Automated Test
 * TC ID        : TC-DOSEN-040
 * Skenario ID : TS-DOSEN-005
 * Modul / Fitur: Kehadiran
 * Judul Test Case: Filter kehadiran berdasarkan tanggal
 * Tipe Kasus  : Positif
 * Prioritas   : Tinggi
 *
 * Sumber        : Hadirin_Test_Scenario_Test_Case.xlsx (Sheet TC Dosen)
 * Pre-kondisi  : Dosen sudah login.
 * Langkah      : 1. Pilih tanggal
 *                2. Lihat data
 * Expected Result: Data kehadiran sesuai tanggal ditampilkan
 *
 * Catatan: halaman Cek Daftar Presensi menampilkan tanggal pilihan pada
 * "Ringkasan Pilihan"; daftar kehadiran saat ini memakai data sesi contoh
 * (lib/data/dosen/lecturer_dummy_data.dart), jadi assertion daftar fokus
 * pada halaman Daftar Kehadiran dan tile mahasiswa yang tampil.
 */

import { expect, $ } from '@wdio/globals';
import {
  dosenLogin,
  formatTanggalId,
  openLecturerAttendance,
  pickPresensiDate,
  showLecturerAttendance,
} from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';
import { LOCATORS } from '../../src/support/selectors';

describe('TC-DOSEN-040 - Filter kehadiran berdasarkan tanggal', () => {
  before(async () => {
    // Pre-condition: dosen sudah login.
    await dosenLogin(
      HADIRIN_DEMO_ACCOUNTS.dosen.email,
      HADIRIN_DEMO_ACCOUNTS.dosen.password,
    );
  });

  it('should display attendance data for the selected date', async () => {
    // Langkah Pengujian:
    // 1. Pilih tanggal
    await openLecturerAttendance();

    const selectedDate = await pickPresensiDate(15);

    // Assertion: tanggal pilihan tampil di kotak tanggal dan ringkasan.
    await expect(
      $(
        `android=new UiSelector().description("${formatTanggalId(selectedDate)}")`,
      ),
    ).toBeDisplayed();

    // 2. Lihat data
    await showLecturerAttendance();

    // Expected Result: data kehadiran ditampilkan.
    await expect($(LOCATORS.dosen.attendance.listTitle)).toBeDisplayed();
    await expect($(LOCATORS.dosen.attendance.summary)).toBeDisplayed();
    await expect($('//*[contains(@content-desc,"Adi Saputra")]')).toBeDisplayed();
  });
});
