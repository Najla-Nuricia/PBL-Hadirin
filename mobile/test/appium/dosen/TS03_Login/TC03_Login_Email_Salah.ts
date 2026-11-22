import { expect, $ } from '@wdio/globals';
import { openLecturerLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';
import { LOCATORS } from '../../src/support/selectors';

describe('TC-DOSEN-010 - Login dosen dengan email salah', () => {
  before(async () => {
    await openLecturerLogin();
  });

  it('should reject login with an unknown email', async () => {
    const emailField = await $(LOCATORS.dosen.login.emailField);
    const passwordField = await $(LOCATORS.dosen.login.passwordField);
    await emailField.click();
    await emailField.clearValue();
    await emailField.setValue('tidak-terdaftar@hadirin.id');
    await passwordField.click();
    await passwordField.clearValue();
    await passwordField.setValue(
      HADIRIN_DEMO_ACCOUNTS.dosen.password,
    );
    await $(LOCATORS.dosen.login.submitButton).click();

    await expect($(LOCATORS.dosen.login.errorSnackbar)).toBeDisplayed();
  });
});
