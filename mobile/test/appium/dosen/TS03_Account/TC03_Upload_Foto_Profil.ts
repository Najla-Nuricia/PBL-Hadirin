import { browser, expect, $ } from '@wdio/globals';
import {
  dosenLogin,
  goToLecturerTab,
} from '../../src/support/actions';
import { HADIRIN_DEMO_ACCOUNTS } from '../../src/support/env';

async function selectFirstPhoto(): Promise<void> {
  await browser.pause(2000);
  const { width, height } = await browser.getWindowSize();
  await browser.execute('mobile: clickGesture', {
    x: Math.round(width * (62 / 375)),
    y: Math.round(height * (464 / 812)),
  });

  const done = $('android=new UiSelector().text("Selesai")');
  if (await done.isDisplayed().catch(() => false)) {
    await done.click();
    return;
  }

  await browser.execute('mobile: clickGesture', {
    x: Math.round(width * (300 / 375)),
    y: Math.round(height * (773 / 812)),
  });
}

describe('TC-DOSEN-013 - Upload foto profil dosen', () => {
  before(async () => {
    await dosenLogin(
      HADIRIN_DEMO_ACCOUNTS.dosen.email,
      HADIRIN_DEMO_ACCOUNTS.dosen.password,
    );
  });

  it('should update the lecturer profile photo', async () => {
    await goToLecturerTab('Profil');
    await $('~Ubah foto profil').click();
    await selectFirstPhoto();

    await expect(
      $('//*[contains(@content-desc,"Foto profil diperbarui")]'),
    ).toBeDisplayed();
  });
});
