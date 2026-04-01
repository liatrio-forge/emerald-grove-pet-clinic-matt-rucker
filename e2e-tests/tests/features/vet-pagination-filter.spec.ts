import { test, expect } from '@playwright/test';
import { VetPage } from '../pages/vet-page';

test.describe('Vet Pagination with Filter Preservation', () => {
  let vetPage: VetPage;

  test.beforeEach(async ({ page }) => {
    vetPage = new VetPage(page);
    await vetPage.open();
  });

  test('should preserve filter param in pagination links', async ({
    page,
  }) => {
    // Apply a filter first
    await vetPage.clickFilterPill('All');

    // Check if pagination exists (needs > 5 vets for multiple pages)
    const paginationLinks = page.locator('.liatrio-pagination a');
    const count = await paginationLinks.count();

    if (count > 0) {
      // Without filter, links should not contain filter param
      const href = await paginationLinks.first().getAttribute('href');
      expect(href).not.toContain('filter=');
    }
  });

  test('should include filter in pagination links when filter active', async ({
    page,
  }) => {
    // Apply a specialty filter
    await vetPage.clickFilterPill('radiology');

    // If pagination exists, links should contain the filter param
    const paginationLinks = page.locator('.liatrio-pagination a');
    const count = await paginationLinks.count();

    if (count > 0) {
      const href = await paginationLinks.first().getAttribute('href');
      expect(href).toContain('filter=radiology');
    }
  });

  test('should maintain active pill after page navigation', async ({
    page,
  }) => {
    // Apply a filter
    await vetPage.clickFilterPill('radiology');

    // The active pill should still show radiology
    const activePill = vetPage.activeFilterPill();
    await expect(activePill).toContainText(/radiology/i);

    // If pagination exists, navigate and check pill is still active
    const nextLink = page.locator('.liatrio-pagination a.fa-step-forward');
    if ((await nextLink.count()) > 0) {
      await nextLink.click();
      await expect(vetPage.activeFilterPill()).toContainText(/radiology/i);
      await expect(page).toHaveURL(/filter=radiology/);
    }
  });
});
