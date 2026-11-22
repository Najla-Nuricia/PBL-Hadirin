import { expect, $ } from '@wdio/globals';
import { openLecturerLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';
import { LOCATORS } from '../../src/support/selectors';

describe('TC-DOSEN-009 - Login dosen dengan password salah', () => {
  before(async () => {
    await openLecturerLogin();
  });

  it('should reject login with the wrong password', async () => {
    const emailField = await $(LOCATORS.dosen.login.emailField);
    const passwordField = await $(LOCATORS.dosen.login.passwordField);
    await emailField.click();
    await emailField.clearValue();
    await emailField.setValue(
      HADIRIN_DEMO_ACCOUNTS.dosen.email,
    );
    await passwordField.click();
    await passwordField.clearValue();
    await passwordField.setValue('password-salah');
    await $(LOCATORS.dosen.login.submitButton).click();

    await expect($(LOCATORS.dosen.login.errorSnackbar)).toBeDisplayed();
  });
});
