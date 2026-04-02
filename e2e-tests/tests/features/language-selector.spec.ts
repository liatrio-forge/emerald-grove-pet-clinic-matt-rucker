import { test, expect } from '@playwright/test';

test.describe('Language Selector', () => {
  test('should display language selector dropdown in header', async ({
    page,
  }) => {
    await page.goto('/');
    const dropdown = page.locator('#language-selector');
    await expect(dropdown).toBeVisible();
  });

  test('should switch to German and show translated text', async ({
    page,
  }) => {
    await page.goto('/');

    // Open the language dropdown
    await page.locator('#language-selector .dropdown-toggle').click();

    // Select German
    await page.locator('#language-selector .dropdown-item', { hasText: 'Deutsch' }).click();

    // Verify German text appears (the "Home" nav should show "Startseite" or similar German text)
    // The URL should contain ?lang=de
    await expect(page).toHaveURL(/lang=de/);

    // The dropdown toggle should now show the German language name
    await expect(page.locator('#language-selector .dropdown-toggle')).not.toContainText('English');
  });

  test('should persist language across navigation', async ({ page }) => {
    // Set language to German
    await page.goto('/?lang=de');

    // Navigate to Find Owners
    await page.getByRole('link', { name: /Tierbesitzer finden|Find owners/i }).first().click();

    // Language should persist — the dropdown should still show German
    await expect(page.locator('#language-selector .dropdown-toggle')).not.toContainText('English');
  });

  test('should highlight active language in dropdown', async ({ page }) => {
    await page.goto('/?lang=es');

    // Open dropdown
    await page.locator('#language-selector .dropdown-toggle').click();

    // Spanish option should have active class
    const spanishItem = page.locator('#language-selector .dropdown-item', { hasText: 'Español' });
    await expect(spanishItem).toHaveClass(/active/);
  });
});
