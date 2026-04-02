import type { Locator, Page } from '@playwright/test';

import { BasePage } from './base-page';

export class UpcomingVisitsPage extends BasePage {
  constructor(page: Page) {
    super(page);
  }

  heading(): Locator {
    return this.page.getByRole('heading', { name: /Upcoming Visits/i });
  }

  visitsTable(): Locator {
    return this.page.locator('table#visits');
  }

  emptyMessage(): Locator {
    return this.page.locator('text=No upcoming visits scheduled');
  }

  async open(): Promise<void> {
    await this.goto('/visits/upcoming');
    await this.heading().waitFor();
  }

  async openWithDays(days: number): Promise<void> {
    await this.goto(`/visits/upcoming?days=${days}`);
    await this.heading().waitFor();
  }
}
