import type { Locator, Page } from '@playwright/test';

import { BasePage } from './base-page';

export class VetPage extends BasePage {
  constructor(page: Page) {
    super(page);
  }

  heading(): Locator {
    return this.page.getByRole('heading', { name: /Veterinarians/i });
  }

  vetsTable(): Locator {
    return this.page.locator('table#vets');
  }

  async open(): Promise<void> {
    await this.goto('/vets.html');
    await this.heading().waitFor();
  }

  filterPills(): Locator {
    return this.page.locator('#specialty-filters a');
  }

  async clickFilterPill(name: string): Promise<void> {
    await this.page
      .locator('#specialty-filters a', { hasText: new RegExp(`^${name}$`, 'i') })
      .click();
  }

  activeFilterPill(): Locator {
    return this.page.locator('#specialty-filters a.btn-primary');
  }
}
