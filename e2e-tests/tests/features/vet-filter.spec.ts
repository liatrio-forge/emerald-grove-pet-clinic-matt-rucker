import { test, expect } from '@playwright/test';
import { VetPage } from '../pages/vet-page';

test.describe('Vet Directory Specialty Filter', () => {
  let vetPage: VetPage;

  test.beforeEach(async ({ page }) => {
    vetPage = new VetPage(page);
    await vetPage.open();
  });

  test('should display specialty filter pills', async () => {
    const pills = vetPage.filterPills();
    const count = await pills.count();
    // At minimum: All + at least one specialty + None
    expect(count).toBeGreaterThanOrEqual(3);
    // First pill should be "All"
    await expect(pills.first()).toContainText(/all/i);
    // Last pill should be "None"
    await expect(pills.last()).toContainText(/none/i);
  });

  test('should filter by specialty when pill clicked', async ({ page }) => {
    await vetPage.clickFilterPill('radiology');

    // URL should contain filter param
    await expect(page).toHaveURL(/filter=radiology/i);

    // All visible vets should have radiology specialty
    const rows = vetPage.vetsTable().locator('tbody tr');
    const count = await rows.count();
    expect(count).toBeGreaterThan(0);
    for (let i = 0; i < count; i++) {
      const specialtyCell = rows.nth(i).locator('td').nth(1);
      await expect(specialtyCell).toContainText(/radiology/i);
    }
  });

  test('should show all vets when All pill clicked', async ({ page }) => {
    // First filter, then click All
    await vetPage.clickFilterPill('radiology');
    await vetPage.clickFilterPill('All');

    // URL should not contain filter param
    expect(page.url()).not.toContain('filter=');
  });

  test('should show only vets with no specialty when None clicked', async ({
    page,
  }) => {
    await vetPage.clickFilterPill('None');

    await expect(page).toHaveURL(/filter.*none/i);

    const rows = vetPage.vetsTable().locator('tbody tr');
    const count = await rows.count();
    expect(count).toBeGreaterThan(0);
    for (let i = 0; i < count; i++) {
      const specialtyCell = rows.nth(i).locator('td').nth(1);
      await expect(specialtyCell).toContainText(/none/i);
    }
  });

  test('should highlight active filter pill', async () => {
    await vetPage.clickFilterPill('radiology');

    const activePill = vetPage.activeFilterPill();
    await expect(activePill).toContainText(/radiology/i);
  });
});
