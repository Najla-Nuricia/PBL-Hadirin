import { expect, $ } from '@wdio/globals';
import { goToStudentTab, mahasiswaLogin } from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

describe('TC-MHS-040 - Password baru kurang dari 8 karakter', () => {
  before(async () => {
    await mahasiswaLogin(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.nim,
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );
  });

  it('should reject a new password shorter than eight characters', async () => {
    await goToStudentTab('Profil');
    await $('~Ubah Kata Sandi').click();

    const currentPasswordField = await $(
      'android=new UiSelector().className("android.widget.EditText").instance(0)',
    );
    const newPasswordField = await $(
      'android=new UiSelector().className("android.widget.EditText").instance(1)',
    );
    const confirmationField = await $(
      'android=new UiSelector().className("android.widget.EditText").instance(2)',
    );

    await currentPasswordField.setValue(
      HADIRIN_DEMO_ACCOUNTS.mahasiswa.password,
    );

    await newPasswordField.click();
    await newPasswordField.setValue('short');
    await confirmationField.click();
    await confirmationField.setValue('short');
    await $('~Simpan').click();

    await expect($('~Kata sandi minimal 8 karakter.')).toBeDisplayed();
  });
});
