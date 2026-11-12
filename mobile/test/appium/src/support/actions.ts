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

export async function dosenLogin(email: string, password: string): Promise<void> {
  // Pre-condition: halaman login dosen ("Login Dosen") terbuka.
  const emailField = await $(LOCATORS.dosen.login.emailField);
  const passwordField = await $(LOCATORS.dosen.login.passwordField);
  const submitButton = await $(LOCATORS.dosen.login.submitButton);

  await emailField.setValue(email);
  await passwordField.setValue(password);
  await submitButton.click();
  await browser.pause(3000);
}

export async function logoutCurrentUser(): Promise<void> {
  await browser.pause(1500);
}
