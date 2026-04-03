import { test, expect } from '@playwright/test';
import { VetPage } from '../pages/vet-page';

test.describe('Vet Filter Pills Visual Design', () => {
  let vetPage: VetPage;

  test.beforeEach(async ({ page }) => {
    vetPage = new VetPage(page);
    await vetPage.open();
  });

  test('should display filter pills container', async ({ page }) => {
    const container = page.locator('#specialty-filters');
    await expect(container).toBeVisible();
    await expect(container).toHaveClass(/liatrio-filter-bar/);
  });

  test('should render each pill with liatrio-filter-pill class', async ({
    page,
  }) => {
    const pills = page.locator('#specialty-filters .liatrio-filter-pill');
    const count = await pills.count();
    expect(count).toBeGreaterThanOrEqual(3); // All + at least 1 specialty + None
  });

  test('should highlight active pill with active class', async ({ page }) => {
    // Default view — "All" should be active
    const activePill = page.locator(
      '#specialty-filters .liatrio-filter-pill--active',
    );
    await expect(activePill).toBeVisible();
    await expect(activePill).toContainText(/all/i);
  });

  test('should switch active class when clicking a specialty', async ({
    page,
  }) => {
    // Click radiology
    await page
      .locator('#specialty-filters .liatrio-filter-pill', {
        hasText: /radiology/i,
      })
      .click();

    // Radiology should now be active
    const activePill = page.locator(
      '#specialty-filters .liatrio-filter-pill--active',
    );
    await expect(activePill).toContainText(/radiology/i);
  });

  test('should render pills with visible rounded borders', async ({
    page,
  }, testInfo) => {
    // Check that an inactive pill has a visible border
    const inactivePill = page
      .locator(
        '#specialty-filters .liatrio-filter-pill:not(.liatrio-filter-pill--active)',
      )
      .first();
    const borderStyle = await inactivePill.evaluate(
      (el) => getComputedStyle(el).borderStyle,
    );
    expect(borderStyle).toBe('solid');

    // Check rounded shape
    const borderRadius = await inactivePill.evaluate(
      (el) => getComputedStyle(el).borderRadius,
    );
    // Should be large (pill shape) — at least 9999px or a large value
    const radiusValue = parseInt(borderRadius);
    expect(radiusValue).toBeGreaterThanOrEqual(10);

    // Take a screenshot for proof
    await page.screenshot({
      path: testInfo.outputPath('vet-filter-pills.png'),
      fullPage: true,
    });
  });
});
