import { test, expect } from '@playwright/test';
import { OwnerPage } from '../pages/owner-page';

test.describe('Pet Deletion', () => {
  const uniqueSuffix = Date.now().toString().slice(-6);
  const testPetName = `DeleteMe${uniqueSuffix}`;

  test('should delete a pet after confirmation on edit form', async ({
    page,
  }) => {
    const ownerPage = new OwnerPage(page);

    // Navigate to George Franklin's owner details
    await ownerPage.openFindOwners();
    await ownerPage.searchByLastName('Franklin');
    await expect(page).toHaveURL(/\/owners\/\d+/);

    // Add a new pet to delete
    await page.getByRole('link', { name: /Add New Pet/i }).click();
    await page.getByLabel(/Name/i).fill(testPetName);
    await page.getByLabel(/Birth Date/i).fill('2020-01-01');
    // Select a pet type
    await page.locator('#type').selectOption({ index: 0 });
    await page.getByRole('button', { name: /Add Pet/i }).click();

    // Verify pet was created — should be on owner details
    await expect(page).toHaveURL(/\/owners\/\d+/);
    await expect(page.locator('body')).toContainText(testPetName);

    // Navigate to the pet's edit page
    await page
      .locator('dd', { hasText: testPetName })
      .locator('..')
      .locator('..')
      .locator('a', { hasText: /Edit Pet/i })
      .click();

    // Accept the confirmation dialog when it appears
    page.on('dialog', (dialog) => dialog.accept());

    // Click the Delete Pet button
    await page.getByRole('button', { name: /Delete Pet/i }).click();

    // Should redirect to owner details with success message
    await expect(page).toHaveURL(/\/owners\/\d+/);
    await expect(page.locator('body')).toContainText(/deleted/i);

    // Pet should no longer appear
    await expect(page.locator('body')).not.toContainText(testPetName);
  });
});
