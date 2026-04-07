# Task 4.0 Proof Artifacts — Chat Widget, Controller, and E2E Test

## Test Results: `./mvnw test`

```
Tests run: 124, Failures: 0, Errors: 0, Skipped: 5
BUILD SUCCESS
```

## Controller Tests: `./mvnw test -Dtest=AssistantControllerTests`

```
Tests run: 3, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

| Test | Validates |
|------|-----------|
| `chatShouldReturnJsonResponse` | POST /api/assistant/chat returns 200 with JSON `response` field |
| `historyShouldReturnEmptyArrayInitially` | GET /api/assistant/history returns 200 with JSON array |
| `chatShouldReturnFriendlyErrorOnFailure` | Empty message returns friendly error, not stack trace |

## Files Created

### Java
- `AssistantController.java` — REST controller with POST /chat and GET /history endpoints
- `AssistantAvailabilityAdvice.java` — ControllerAdvice exposing `assistantEnabled` model attribute
- `AssistantControllerTests.java` — 3 WebMvcTest tests using StubChatModel
- `StubChatModel.java` — Test stub implementing ChatModel interface

### UI
- `fragments/chat-widget.html` — Floating chat widget with FAB, panel, inline JS
- `petclinic.css` — ~200 lines of chat widget CSS following STYLE_GUIDE.md

### E2E
- `e2e-tests/tests/features/ai-assistant.spec.ts` — 3 Playwright tests (skip when no API key)

## Files Modified
- `fragments/layout.html` — Added conditional chat widget include before `</body>`
- `messages/*.properties` — Added assistant.title, assistant.welcome, assistant.placeholder keys (all 9 locale files)

## Accessibility Features
- FAB: `aria-label="Open AI Assistant"`
- Close button: `aria-label="Close chat"`
- Chat panel: `role="dialog"`, `aria-label="AI Assistant chat"`
- Messages area: `role="log"`, `aria-live="polite"`
- Input: `aria-label="Chat message"`
- Send button: `aria-label="Send message"`
- Focus-visible styles on FAB and close button
- Responsive: full-width on mobile (< 480px)

## Design System Compliance
- Panel background: `#1E2327`, border: `#333333`, radius: `16px`
- Header: `#111111` background
- User bubbles: `rgba(36, 174, 29, 0.15)` (green tint)
- Assistant bubbles: `#111111`
- Links: `#89df00` (lime accent)
- Input: `#111111` background, `#24AE1D` focus ring
- Font: DM Sans (inherited from layout)

## Security Hardening
- XSS fix: `escapeHtml()` applied before `innerHTML` in `appendMessage()` — prevents malicious HTML in AI responses
- Error logging added to controller (`logger.error`) for debugging without exposing internals to users
- No destructive tools (delete/update) exposed to the AI

## Manual Verification
- Web-design-guidelines audit: PASS (all WCAG AA, ARIA, focus, STYLE_GUIDE.md checks)
- Live chat tested with real Anthropic API key — tool calling works end-to-end
- Full test suite: 124 tests, 0 failures
