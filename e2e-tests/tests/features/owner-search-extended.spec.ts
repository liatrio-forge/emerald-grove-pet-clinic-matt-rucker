import { test, expect } from '@playwright/test';
import { OwnerPage } from '../pages/owner-page';

test.describe('Extended Owner Search', () => {
  let ownerPage: OwnerPage;

  test.beforeEach(async ({ page }) => {
    ownerPage = new OwnerPage(page);
  });

  test('should search by telephone and find matching owner', async ({
    page,
  }) => {
    // Arrange — navigate to find owners
    await ownerPage.openFindOwners();

    // Act — search by telephone for a known sample data owner (George Franklin)
    await ownerPage.searchByTelephone('6085551023');

    // Assert — should redirect to owner details (single result)
    await expect(page).toHaveURL(/\/owners\/\d+/);
    await expect(page.locator('body')).toContainText('George Franklin');
  });

  test('should search by city and show results', async ({ page }) => {
    // Arrange
    await ownerPage.openFindOwners();

    // Act — search by city "Madison" (sample data has owners in Madison)
    await ownerPage.searchByCity('Madison');

    // Assert — should show results (could be one or more)
    await expect(
      page.locator('table#owners, body:has-text("George Franklin")'),
    ).toBeVisible();
  });

  test('should search by multiple fields', async ({ page }) => {
    // Arrange
    await ownerPage.openFindOwners();

    // Act
    await ownerPage.searchByMultipleFields({
      lastName: 'Franklin',
      city: 'Madison',
    });

    // Assert — George Franklin matches both criteria
    await expect(page).toHaveURL(/\/owners\/\d+/);
    await expect(page.locator('body')).toContainText('George Franklin');
  });

  test('should show validation error for invalid telephone', async ({
    page,
  }) => {
    // Arrange
    await ownerPage.openFindOwners();

    // Act — enter invalid telephone
    await ownerPage.searchByTelephone('abc');

    // Assert — should stay on find form with error
    await expect(page).toHaveURL(/\/owners\?/);
    await expect(page.locator('body')).toContainText(/10 digits|invalid/i);
  });

  test('should preserve search params in pagination URLs', async ({
    page,
  }) => {
    // Arrange — search with lastName that returns multiple results
    await ownerPage.openFindOwners();
    await ownerPage.searchByLastName('');

    // Assert — if pagination exists, links should contain search params
    const paginationLinks = page.locator('.liatrio-pagination a');
    const count = await paginationLinks.count();
    if (count > 0) {
      const href = await paginationLinks.first().getAttribute('href');
      expect(href).toContain('lastName=');
    }
  });
});
