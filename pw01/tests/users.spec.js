// @ts-check
import { test, expect } from '@playwright/test';

test('has title', async ({ page }) => {
  await page.goto('/users');

  // Expect a title "to contain" a substring.
  await expect(page).toHaveTitle(/Myapp/);
});

test('get new user link', async ({ page }) => {
  await page.goto('/users');

  // Click the get started link.
  await page.getByRole('link', { name: 'New User' }).click();

  // Expects page to have a heading with the name of Installation.
  await expect(page.getByRole('heading', { name: 'New User' })).toBeVisible();
});
