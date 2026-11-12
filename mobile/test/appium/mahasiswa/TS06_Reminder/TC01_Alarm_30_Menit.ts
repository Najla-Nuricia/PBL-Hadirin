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

import { expect, $ } from '@wdio/globals';
import { mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';
import {
  advanceToReminderWindow,
  FakeClock,
} from '../../src/support/clock';

describe('TC-MHS-014 - Alarm 30 menit sebelum kelas', () => {
  before(async () => {
    // Pre-condition: jadwal kelas tersedia.
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should show reminder before class starts', async () => {
    // Langkah Pengujian:
    // 1. Tunggu hingga 30 menit sebelum kelas
    //
    // Expected Result: Alarm / pengingat muncul

    const classStart = new Date();
    classStart.setMinutes(classStart.getMinutes() + 31);
    const clock = new FakeClock(
      new Date(classStart.getTime() - 31 * 60 * 1000),
    );
    advanceToReminderWindow(clock, classStart);

    const notifikasi = await $('~Pengingat kelas');
    await notifikasi.waitForDisplayed({ timeout: 10000 });
    await expect(notifikasi).toBeDisplayed();
  });
});
