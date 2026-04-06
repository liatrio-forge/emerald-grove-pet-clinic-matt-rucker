import { test, expect } from '@fixtures/base-test';

test.describe('AI Assistant Chat Widget', () => {
  // Skip all tests if ANTHROPIC_API_KEY is not set
  test.skip(
    !process.env.ANTHROPIC_API_KEY,
    'ANTHROPIC_API_KEY environment variable is required for AI assistant tests'
  );

  test('chat widget FAB is visible and opens panel', async ({ page }) => {
    await page.goto('/');

    const fab = page.locator('#chat-fab');
    await expect(fab).toBeVisible();

    await fab.click();

    const panel = page.locator('#chat-panel');
    await expect(panel).toBeVisible();

    const header = panel.locator('.chat-header-title');
    await expect(header).toHaveText(/AI Assistant/i);
  });

  test('can send a message and receive a response', async ({ page }) => {
    await page.goto('/');

    // Open chat widget
    await page.locator('#chat-fab').click();
    await expect(page.locator('#chat-panel')).toBeVisible();

    // Type and send a message
    const input = page.locator('#chat-input');
    await input.fill('List all pet types');
    await page.locator('#chat-send').click();

    // Verify user message appears
    const userMessages = page.locator('.chat-message-user');
    await expect(userMessages.last()).toContainText('List all pet types');

    // Wait for assistant response (may take a few seconds with real API)
    const assistantMessages = page.locator('.chat-message-assistant');
    await expect(assistantMessages).toHaveCount(2, { timeout: 30000 }); // welcome + response
  });

  test('chat widget persists across page navigation', async ({ page }) => {
    await page.goto('/');

    // Open chat widget
    await page.locator('#chat-fab').click();
    await expect(page.locator('#chat-panel')).toBeVisible();

    // Navigate to a different page
    await page.goto('/owners/find');

    // Widget should still be open (sessionStorage preserves state)
    await expect(page.locator('#chat-panel')).toBeVisible();
  });
});
