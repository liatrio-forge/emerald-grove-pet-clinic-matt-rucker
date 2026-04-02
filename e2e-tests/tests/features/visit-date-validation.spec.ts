import { test, expect } from '@playwright/test';
import { OwnerPage } from '../pages/owner-page';
import { VisitPage } from '../pages/visit-page';

test.describe('Visit Date Validation', () => {
  test('should reject a visit with a past date', async ({ page }) => {
    const ownerPage = new OwnerPage(page);
    const visitPage = new VisitPage(page);

    // Navigate to a known owner's pet visit form (George Franklin, pet Max)
    await ownerPage.openFindOwners();
    await ownerPage.searchByLastName('Franklin');

    // Should redirect to owner details (single result)
    await expect(page).toHaveURL(/\/owners\/\d+/);

    // Click "Add Visit" for the first pet
    await page.getByRole('link', { name: /Add Visit/i }).first().click();
    await expect(visitPage.heading()).toBeVisible();

    // Enter a past date
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const pastDate = yesterday.toISOString().split('T')[0];

    await visitPage.fillVisitDate(pastDate);
    await visitPage.fillDescription('Past date checkup');
    await visitPage.submit();

    // Should stay on the form with an error
    await expect(page.locator('body')).toContainText(
      /present or in the future|future or present/i,
    );
  });

  test('should accept a visit with today date', async ({ page }) => {
    const ownerPage = new OwnerPage(page);
    const visitPage = new VisitPage(page);

    await ownerPage.openFindOwners();
    await ownerPage.searchByLastName('Franklin');
    await expect(page).toHaveURL(/\/owners\/\d+/);

    await page.getByRole('link', { name: /Add Visit/i }).first().click();

    const today = new Date().toISOString().split('T')[0];
    await visitPage.fillVisitDate(today);
    await visitPage.fillDescription('Today checkup');
    await visitPage.submit();

    // Should redirect to owner details with success
    await expect(page).toHaveURL(/\/owners\/\d+/);
    await expect(page.locator('body')).toContainText(
      /visit has been booked/i,
    );
  });
});
