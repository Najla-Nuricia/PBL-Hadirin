import { browser, driver, $ } from '@wdio/globals';
import { LOCATORS } from './selectors';

/**
 * Reusable UI actions for the Hadirin mobile app (Appium / UiAutomator2).
 *
 * Login selectors use the standard Android widget hierarchy exposed by the
 * Flutter app. Replace them with accessibility IDs when the app exposes them.
 */

export async function waitForLoginScreen(): Promise<void> {
  await $(LOCATORS.mahasiswa.login.title).waitForDisplayed();
}

export async function openStudentLogin(): Promise<void> {
  const loginTitle = await $(LOCATORS.mahasiswa.login.title);
  if (await loginTitle.isDisplayed().catch(() => false)) return;

  const next = await $(LOCATORS.onboarding.next);
  if (await next.isDisplayed().catch(() => false)) {
    await next.click();
  }

  await $(LOCATORS.onboarding.mahasiswa).waitForDisplayed();
  await $(LOCATORS.onboarding.mahasiswa).click();
  await waitForLoginScreen();
}

export async function openStudentRegistration(): Promise<void> {
  await openStudentLogin();
  await $('~Daftar').click();
  await $(LOCATORS.mahasiswa.register.title).waitForDisplayed();
}

const FOCUSED_EDIT =
  'android=new UiSelector().className("android.widget.EditText").focused(true)';

export async function fillField(
  selector: string,
  value: string,
): Promise<void> {
  if (await driver.isKeyboardShown()) {
    await driver.hideKeyboard();
    await browser.pause(800);
  }

  try {
    const field = await $(selector);
    await field.waitForDisplayed({ timeout: 10000 });
    await field.click();
    await browser.pause(800);
  } catch (error) {
    if (!selector.includes('instance(4)')) throw error;

    const passwordField = await $(
      selector.replace('instance(4)', 'instance(3)'),
    );
    await passwordField.waitForDisplayed({ timeout: 10000 });
    await passwordField.click();
    await driver.pressKeyCode(61);
    await browser.pause(500);
  }

  const focusedField = await $(FOCUSED_EDIT);
  await focusedField.waitForExist({ timeout: 5000 });
  await focusedField.setValue(value);
}

export async function tapSubmitRegistrasi(): Promise<void> {
  if (await driver.isKeyboardShown().catch(() => false)) {
    await driver.pressKeyCode(4); // Back, cuma nutup keyboard
    await browser.pause(800);
  }

  const submitButton = await $(LOCATORS.mahasiswa.register.submitButton);
  await submitButton.waitForDisplayed({ timeout: 10000 });
  await submitButton.click();
}

export async function adminLogin(username: string, password: string): Promise<void> {
  // Pre-condition: halaman login admin ("Login Sekretaris Jurusan") terbuka.
  const usernameField = await $(LOCATORS.admin.login.usernameField);
  const passwordField = await $(LOCATORS.admin.login.passwordField);
  const submitButton = await $(LOCATORS.admin.login.submitButton);

  await usernameField.setValue(username);
  await passwordField.setValue(password);
  await submitButton.click();
  await browser.pause(3000);
}

export async function mahasiswaLogin(nim: string, password: string): Promise<void> {
  await openStudentLogin();
  const nimField = await $(LOCATORS.mahasiswa.login.nimField);
  const passwordField = await $(LOCATORS.mahasiswa.login.passwordField);
  const submitButton = await $(LOCATORS.mahasiswa.login.submitButton);

  await nimField.click();
  await nimField.clearValue();
  await nimField.setValue(nim);
  await passwordField.click();
  await passwordField.clearValue();
  await passwordField.setValue(password);
  await submitButton.click();
  await browser.pause(2500);
}

export async function goToStudentTab(label: string): Promise<void> {
  const accessibilityTab = await $(`~${label}`);
  const tab = (await accessibilityTab.isDisplayed().catch(() => false))
    ? accessibilityTab
    : await $(`android=new UiSelector().text("${label}")`);
  await tab.waitForDisplayed();
  await tab.click();
  await browser.pause(1000);
}

export async function tapProfileChangePassword(selector: string): Promise<void> {
  const action = await $(selector);
  if (await action.isDisplayed().catch(() => false)) {
    await action.click();
    return;
  }

  const { width, height } = await browser.getWindowSize();
  await browser.execute('mobile: clickGesture', {
    x: Math.round(width * 0.5),
    y: Math.round(height * 0.67),
  });
}

export async function dosenLogin(email: string, password: string): Promise<void> {
  await openLecturerLogin();
  const emailField = await $(LOCATORS.dosen.login.emailField);
  const passwordField = await $(LOCATORS.dosen.login.passwordField);
  const submitButton = await $(LOCATORS.dosen.login.submitButton);

  await emailField.click();
  await emailField.clearValue();
  await emailField.setValue(email);
  await passwordField.click();
  await passwordField.clearValue();
  await passwordField.setValue(password);
  await submitButton.click();
  await browser.pause(2500);
}

export async function openLecturerLogin(): Promise<void> {
  const loginTitle = await $(LOCATORS.dosen.login.title);
  if (await loginTitle.isDisplayed().catch(() => false)) return;

  const next = await $(LOCATORS.onboarding.next);
  if (await next.isDisplayed().catch(() => false)) {
    await next.click();
  }

  await $(LOCATORS.onboarding.dosen).waitForDisplayed();
  await $(LOCATORS.onboarding.dosen).click();
  await loginTitle.waitForDisplayed();
}

export async function openLecturerRegistration(): Promise<void> {
  await openLecturerLogin();
  await $('~Daftar').click();
  await $(LOCATORS.dosen.register.title).waitForDisplayed();
}

export async function goToLecturerTab(label: string): Promise<void> {
  const accessibilityTab = await $(`~${label}`);
  const tab = (await accessibilityTab.isDisplayed().catch(() => false))
    ? accessibilityTab
    : await $(`android=new UiSelector().text("${label}")`);
  await tab.waitForDisplayed();
  await tab.click();
  await browser.pause(1000);
}

/** Buka dashboard kehadiran dosen (Cek Daftar Presensi). */
export async function openLecturerAttendance(): Promise<void> {
  await goToLecturerTab('Kehadiran');
  await $(LOCATORS.dosen.attendance.title).waitForDisplayed();
}

/**
 * Selector tanggal pada halaman Cek Daftar Presensi.
 *
 * Hanya memakai tanggal (hari) ke-`day`, bukan bulan/tahun, karena DatePicker
 * memakai tanggal device (emulator) sedangkan runner memakai tanggal host.
 * Contoh teks di app: "Minggu, 15 November 2026".
 */
export function presensiDateSelector(day: number): string {
  return `//*[contains(@content-desc,", ${day} ")]`;
}

/**
 * Pilih tanggal lewat dialog DatePicker lalu tekan OK.
 * Hari selalu berada di bulan berjalan (initialDate = hari ini).
 */
export async function pickPresensiDate(day: number): Promise<void> {
  const okButton = await $(LOCATORS.dosen.attendance.datePickerOk);
  const dateBox = await $(LOCATORS.dosen.attendance.dateBox);
  await dateBox.waitForDisplayed();
  await dateBox.click();

  // Fallback: tap area kotak tanggal tepat di bawah label "Tanggal".
  if (!(await okButton.isDisplayed().catch(() => false))) {
    const label = await $('~Tanggal');
    const { x, y } = await label.getLocation();
    const { width } = await label.getSize();
    await browser.execute('mobile: clickGesture', {
      x: Math.round(x + width / 2),
      y: Math.round(y + 40),
    });
  }

  await okButton.waitForDisplayed();
  await browser.pause(800); // tunggu animasi dialog DatePicker selesai

  // Sel tanggal bisa diekspos sebagai content-desc (semantics Flutter) atau
  // sebagai text biasa, tergantung versi driver. Coba keduanya.
  const dayCellSelectors = [
    `//*[starts-with(@content-desc,"${day}, ") and @clickable="true"]`,
    LOCATORS.dosen.attendance.datePickerDay(day),
    `//*[@text="${day}"]`,
    `android=new UiSelector().text("${day}")`,
  ];

  let dayCell = null;
  for (const selector of dayCellSelectors) {
    const candidate = await $(selector);
    const visible = await candidate
      .waitForDisplayed({ timeout: 2000 })
      .then(() => true)
      .catch(() => false);
    if (visible) {
      dayCell = candidate;
      break;
    }
  }
  if (!dayCell) {
    throw new Error(`Sel tanggal ${day} tidak ditemukan pada DatePicker.`);
  }

  // Tap lewat koordinat sel; element.click() pada node semantics Flutter
  // kadang tidak memilih tanggal di DatePicker.
  const { x, y } = await dayCell.getLocation();
  const { width, height } = await dayCell.getSize();
  if (width > 0 && height > 0) {
    await browser.execute('mobile: clickGesture', {
      x: Math.round(x + width / 2),
      y: Math.round(y + height / 2),
    });
  } else {
    await dayCell.click();
  }
  await browser.pause(800); // tunggu tanggal terpilih (setState)

  // Setelah memilih tanggal, baru konfirmasi dengan tombol OK.
  // Query ulang karena node semantics dialog bisa berubah setelah setState.
  await $(LOCATORS.dosen.attendance.datePickerOk).click();
  await $(LOCATORS.dosen.attendance.title).waitForDisplayed();
}

/** Pilih nilai dropdown Kelas / Mata Kuliah pada Cek Daftar Presensi. */
export async function selectPresensiValue(
  currentValue: string,
  nextValue: string,
): Promise<void> {
  const dropdown = await $(
    LOCATORS.dosen.attendance.selectedOption(currentValue),
  );
  await dropdown.waitForDisplayed();
  await dropdown.click();

  const option = await $(LOCATORS.dosen.attendance.option(nextValue));
  await option.waitForDisplayed({ timeout: 10000 });
  await option.click();
  await browser.pause(800);
}

/** Tekan "Tampilkan Data" lalu tunggu halaman Daftar Kehadiran terbuka. */
export async function showLecturerAttendance(): Promise<void> {
  await $(LOCATORS.dosen.attendance.showDataButton).click();
  await $(LOCATORS.dosen.attendance.listTitle).waitForDisplayed({
    timeout: 10000,
  });
}

/**
 * Semantics tile mahasiswa pada halaman Daftar Kehadiran, mis.
 * "Adi Saputra, NIM 2211001, status Hadir, jam 07:58. Ketuk untuk melihat detail."
 */
export function lecturerStudentTile(
  name: string,
  checkInTime?: string,
): string {
  const timeFilter = checkInTime
    ? ` and contains(@content-desc,"jam ${checkInTime}")`
    : '';
  return `//*[contains(@content-desc,"${name}")${timeFilter}]`;
}

export async function tapSubmitLecturerRegistration(): Promise<void> {
  if (await driver.isKeyboardShown().catch(() => false)) {
    await driver.pressKeyCode(4);
    await browser.pause(800);
  }

  const submitButton = await $(LOCATORS.dosen.register.submitButton);
  await submitButton.waitForDisplayed({ timeout: 10000 });
  await submitButton.click();
}

export async function logoutCurrentUser(): Promise<void> {
  await browser.pause(1500);
}
