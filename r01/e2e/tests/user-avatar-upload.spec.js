import { fileURLToPath } from 'node:url';
import { test, expect } from '@playwright/test';

const imagePath = fileURLToPath(new URL('../../spec/fixtures/files/test_image.jpg', import.meta.url));

test('ユーザーの画像をアップロードし、保存後も表示できる', async ({ page }) => {
  const userName = `playwright-avatar-${Date.now()}`;
  let userUrl;

  try {
    await page.goto('/users/new');
    await page.getByLabel('Name', { exact: true }).fill(userName);
    // Stimulus の非同期読み込みが完了してからファイルを選択する。
    await expect.poll(() => page.evaluate(() => Boolean(
      window.Stimulus?.getControllerForElementAndIdentifier(
        document.querySelector('[data-controller="user"]'), 'user'
      )
    ))).toBe(true);
    const uploadResponsePromise = page.waitForResponse((response) =>
      new URL(response.url()).pathname === '/api/v1/user_avatars' &&
      response.request().method() === 'POST'
    );
    await page.getByLabel('Avatar', { exact: true }).setInputFiles(imagePath);
    const uploadResponse = await uploadResponsePromise;
    expect(uploadResponse.ok(), `画像アップロード API: HTTP ${uploadResponse.status()}`).toBe(true);

    const preview = page.locator('[data-user-target="avatarImageArea"] img');
    await expect(preview).toBeVisible();
    await expect.poll(() => preview.evaluate((image) => image.naturalWidth)).toBeGreaterThan(0);
    const imageUrl = await preview.getAttribute('src');

    await page.getByRole('button', { name: 'Create User' }).click();
    await expect(page.getByText('User was successfully created.')).toBeVisible();
    userUrl = page.url();
    await expect(page.getByText(userName)).toBeVisible();

    // 再読み込みして、画像とユーザーの関連付けが保存されていることを確認する。
    await page.reload();
    const avatar = page.locator('[id^="user_"] img');
    await expect(avatar).toHaveAttribute('src', imageUrl);
    await expect(avatar).toBeVisible();
    await expect.poll(() => avatar.evaluate((image) => image.naturalWidth)).toBeGreaterThan(0);
  } finally {
    if (userUrl) {
      await page.goto(userUrl);
      page.once('dialog', (dialog) => dialog.accept());
      await page.getByRole('button', { name: 'Destroy this user' }).click();
      await expect(page.getByText('User was successfully destroyed.')).toBeVisible();
    }
  }
});
