import { test, expect } from '@playwright/test';

const userName = `playwright-user-${Date.now()}`;

test('users CRUD がブラウザ経由で動作する', async ({ page }) => {
  await page.goto('/users');

  await expect(page.getByRole('heading', { name: 'Users' })).toBeVisible();

  await page.getByRole('link', { name: 'New user' }).click();
  await expect(page.getByRole('heading', { name: 'New user' })).toBeVisible();

  await page.getByLabel('Name').fill(userName);
  await page.getByRole('button', { name: 'Create User' }).click();

  await expect(page.getByText('User was successfully created.')).toBeVisible();
  await expect(page.getByText(userName)).toBeVisible();

  await page.getByRole('link', { name: 'Edit this user' }).click();
  await expect(page.getByRole('heading', { name: 'Editing user' })).toBeVisible();

  const updatedUserName = `${userName}-updated`;
  await page.getByLabel('Name').fill(updatedUserName);
  await page.getByRole('button', { name: 'Update User' }).click();

  await expect(page.getByText('User was successfully updated.')).toBeVisible();
  await expect(page.getByText(updatedUserName)).toBeVisible();

  page.on('dialog', (dialog) => dialog.accept());
  await page.getByRole('button', { name: 'Destroy this user' }).click();

  await expect(page.getByText('User was successfully destroyed.')).toBeVisible();
  await expect(page.getByRole('link', { name: 'New user' })).toBeVisible();
});
