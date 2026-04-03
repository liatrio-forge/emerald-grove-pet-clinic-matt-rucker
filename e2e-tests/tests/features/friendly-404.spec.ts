import { test, expect } from '@playwright/test';

test.describe('Friendly 404 Pages', () => {
  test('should show friendly 404 for non-existent owner', async ({
    page,
  }) => {
    const response = await page.goto('/owners/99999');

    // Should return 404 status
    expect(response?.status()).toBe(404);

    // Should show friendly message
    await expect(page.locator('body')).toContainText(/not found/i);

    // Should show "Back to Find Owners" link
    const backLink = page.getByRole('link', { name: /Find Owners/i });
    await expect(backLink).toBeVisible();

    // Click the link and verify it goes to Find Owners
    await backLink.click();
    await expect(page).toHaveURL(/\/owners\/find/);
  });

  test('should show friendly 404 for non-existent pet', async ({ page }) => {
    // Navigate to a known owner but non-existent pet
    const response = await page.goto('/owners/1/pets/99999/edit');

    // Should return 404 status
    expect(response?.status()).toBe(404);

    // Should show friendly message
    await expect(page.locator('body')).toContainText(/not found/i);
  });

  test('should not expose stack traces on 404', async ({ page }) => {
    await page.goto('/owners/99999');

    // Should NOT contain stack trace indicators
    const body = await page.locator('body').textContent();
    expect(body).not.toContain('IllegalArgumentException');
    expect(body).not.toContain('java.lang');
    expect(body).not.toContain('at org.springframework');
  });

  test('should still show 500 for actual server errors', async ({ page }) => {
    const response = await page.goto('/oups');

    // The crash controller should still return 500
    expect(response?.status()).toBe(500);
  });
});
