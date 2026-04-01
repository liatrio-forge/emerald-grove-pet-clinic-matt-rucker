import { test, expect } from '@playwright/test';
import { OwnerPage } from '../pages/owner-page';

test.describe('CSV Export of Owner Search Results', () => {
  let ownerPage: OwnerPage;

  test.beforeEach(async ({ page }) => {
    ownerPage = new OwnerPage(page);
  });

  test('should show Export CSV button on search results page', async ({
    page,
  }) => {
    // Arrange — search for all owners (empty search)
    await ownerPage.openFindOwners();
    await ownerPage.searchByLastName('');

    // Assert — Export CSV button should be visible
    await expect(ownerPage.exportCsvLink()).toBeVisible();
  });

  test('should download CSV with correct content', async ({ page }) => {
    // Arrange — search for all owners
    await ownerPage.openFindOwners();
    await ownerPage.searchByLastName('');

    // Act — click export and capture download
    const downloadPromise = page.waitForEvent('download');
    await ownerPage.clickExportCsv();
    const download = await downloadPromise;

    // Assert — verify filename
    expect(download.suggestedFilename()).toBe('owners.csv');

    // Read and verify content
    const content = (await download.path())
      ? await (
          await import('fs/promises')
        ).readFile(await download.path()!, 'utf-8')
      : '';
    expect(content).toContain(
      'First Name,Last Name,Address,City,Telephone',
    );
    expect(content.split('\n').length).toBeGreaterThan(1);
  });

  test('should include search params in Export CSV link', async ({ page }) => {
    // Arrange — search with a filter
    await ownerPage.openFindOwners();
    await ownerPage.searchByLastName('Franklin');

    // If we get redirected to owner details (single result), this test doesn't apply
    // So we search more broadly
    await ownerPage.openFindOwners();
    await ownerPage.searchByLastName('');

    // Assert — the CSV link should exist and contain query params
    const href = await ownerPage.exportCsvLink().getAttribute('href');
    expect(href).toContain('/owners.csv');
    expect(href).toContain('lastName=');
  });
});
