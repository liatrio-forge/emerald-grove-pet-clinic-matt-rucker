import { test, expect } from '@playwright/test';
import { OwnerPage } from '../pages/owner-page';

test.describe('Duplicate Owner Detection', () => {
  const uniqueSuffix = Date.now().toString().slice(-6);
  const testOwner = {
    firstName: `DupTest`,
    lastName: `Owner${uniqueSuffix}`,
    address: '123 Test Street',
    city: 'TestCity',
    telephone: `55${uniqueSuffix.padStart(8, '0')}`,
  };

  test('should reject duplicate owner creation and show error', async ({
    page,
  }) => {
    const ownerPage = new OwnerPage(page);

    // Create the first owner
    await ownerPage.openFindOwners();
    await ownerPage.clickAddOwner();
    await ownerPage.fillOwnerForm(testOwner);
    await ownerPage.submitOwnerForm();

    // Verify first creation succeeded — should redirect to owner details
    await expect(page).toHaveURL(/\/owners\/\d+/);

    // Attempt to create the same owner again
    await ownerPage.openFindOwners();
    await ownerPage.clickAddOwner();
    await ownerPage.fillOwnerForm(testOwner);
    await ownerPage.submitOwnerForm();

    // Should stay on the form with a duplicate error
    await expect(page.locator('.alert-danger')).toContainText(
      /already exists/i,
    );

    // Verify no second record was created — search should find exactly one
    await ownerPage.openFindOwners();
    await ownerPage.searchByLastName(testOwner.lastName);

    // Single result should redirect to owner details (not a list)
    await expect(page).toHaveURL(/\/owners\/\d+/);
  });
});
