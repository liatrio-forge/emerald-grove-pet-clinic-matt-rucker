import type { Locator, Page } from '@playwright/test';

import { BasePage } from './base-page';

export type OwnerFormData = {
  firstName: string;
  lastName: string;
  address: string;
  city: string;
  telephone: string;
};

export class OwnerPage extends BasePage {
  constructor(page: Page) {
    super(page);
  }

  heading(): Locator {
    return this.page.getByRole('heading', { level: 2 });
  }

  ownersTable(): Locator {
    return this.page.locator('table#owners');
  }

  async openFindOwners(): Promise<void> {
    await this.goto('/owners/find');
    await this.page.getByRole('heading', { name: /Find Owners/i }).waitFor();
  }

  async searchByLastName(lastName: string): Promise<void> {
    await this.page.locator('input#lastName').fill(lastName);
    await this.page.getByRole('button', { name: /Find Owner/i }).click();
  }

  async clickAddOwner(): Promise<void> {
    await this.page.getByRole('link', { name: /Add Owner/i }).click();
  }

  async fillOwnerForm(owner: OwnerFormData): Promise<void> {
    await this.page.getByLabel(/First Name/i).fill(owner.firstName);
    await this.page.getByLabel(/Last Name/i).fill(owner.lastName);
    await this.page.getByLabel(/Address/i).fill(owner.address);
    await this.page.getByLabel(/City/i).fill(owner.city);
    await this.page.getByLabel(/Telephone/i).fill(owner.telephone);
  }

  async fillCity(city: string): Promise<void> {
    await this.page.getByLabel(/City/i).fill(city);
  }

  async submitOwnerForm(): Promise<void> {
    await this.page.getByRole('button', { name: /Add Owner|Update Owner/i }).click();
  }

  async openOwnerDetailsByName(fullName: string): Promise<void> {
    await this.ownersTable().getByRole('link', { name: fullName }).click();
  }

  async clickEditOwner(): Promise<void> {
    await this.page.getByRole('link', { name: /Edit Owner/i }).click();
  }

  async searchByTelephone(telephone: string): Promise<void> {
    await this.page.locator('input#telephone').fill(telephone);
    await this.page.getByRole('button', { name: /Find Owner/i }).click();
  }

  async searchByCity(city: string): Promise<void> {
    await this.page.locator('input#city').fill(city);
    await this.page.getByRole('button', { name: /Find Owner/i }).click();
  }

  async searchByMultipleFields(params: {
    lastName?: string;
    telephone?: string;
    city?: string;
  }): Promise<void> {
    if (params.lastName) {
      await this.page.locator('input#lastName').fill(params.lastName);
    }
    if (params.telephone) {
      await this.page.locator('input#telephone').fill(params.telephone);
    }
    if (params.city) {
      await this.page.locator('input#city').fill(params.city);
    }
    await this.page.getByRole('button', { name: /Find Owner/i }).click();
  }

  async clickExportCsv(): Promise<void> {
    await this.page.locator('#export-csv').click();
  }

  exportCsvLink(): Locator {
    return this.page.locator('#export-csv');
  }
}
