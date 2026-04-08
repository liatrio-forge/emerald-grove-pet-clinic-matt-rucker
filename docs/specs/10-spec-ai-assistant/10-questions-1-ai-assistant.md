# 10 Questions Round 1 - AI Assistant

Please answer each question below (select one or more options, or add your own notes). Feel free to add additional context under any question.

## 1. User Persona and Access

Who is the intended user of the AI assistant? This affects the system prompt, what actions are allowed, and how the UI is framed.

- [ ] (A) Clinic staff (receptionists, office managers) — the assistant helps them manage day-to-day operations faster
- [x] (B) Pet owners — a self-service portal where owners can check their pet info and book visits
- [ ] (C) Both — but with the same unrestricted access (simpler to build)
- [ ] (D) Both — with role-based restrictions (owners can only see their own data)
- [ ] (E) Other (describe)

## 2. Confirmation Before Write Operations

The assistant can create owners, add pets, and book visits. Should it confirm with the user before executing write operations?

- [x] (A) Always confirm — show what will be created and ask "Should I proceed?" before executing
- [ ] (B) Confirm for creates only — searching and viewing don't need confirmation, but creating/modifying does
- [ ] (C) No confirmation — execute immediately and show the result (faster, but riskier)
- [ ] (D) Other (describe)

## 3. Response Format

How should the assistant present structured data (e.g., search results with multiple owners, pet lists)?

- [ ] (A) Plain text — simple formatted text responses, easy to implement
- [ ] (B) Markdown-rendered — use markdown formatting (bold, lists, tables) rendered in the chat UI
- [x] (C) Hybrid — text for conversational responses, but link to existing app pages for detailed views (e.g., "I found George Franklin — [view details](/owners/1)")
- [ ] (D) Other (describe)

## 4. Claude Model Selection

Which Claude model should the assistant use? This affects cost, speed, and capability.

- [ ] (A) Claude Sonnet (claude-sonnet-4-20250514) — good balance of speed and capability, recommended for tool use
- [ ] (B) Claude Haiku (claude-haiku-4-5-20251001) — fastest and cheapest, may struggle with complex multi-step tasks
- [x] (C) Configurable via application.properties — let the deployer choose (default to Sonnet)
- [ ] (D) Other (describe)

## 5. Error Handling When AI Service Is Unavailable

What should happen if the Anthropic API key is not set or the API is unreachable?

- [x] (A) Hide the assistant nav link entirely — feature is invisible without a valid API key
- [ ] (B) Show the page but display a friendly "AI Assistant is not configured" message
- [ ] (C) Show the page, let users type, but return a helpful error on send ("AI service is currently unavailable")
- [ ] (D) Other (describe)

## 6. Conversation Scope and Reset

How should conversation sessions work?

- [x] (A) Per browser session — conversation persists until the browser session expires or user clears it
- [ ] (B) Per page visit — fresh conversation every time you navigate to /assistant
- [ ] (C) Explicit reset — persist across page visits within a session, but provide a "New Conversation" button
- [ ] (D) Other (describe)

## 7. Proof Artifacts

What would best demonstrate this feature is working for your learning exercise review?

- [x] (A) Playwright E2E test that sends a message and verifies a response appears in the chat UI
- [ ] (B) Screenshot/recording of a multi-turn conversation (search owner → view pet → book visit)
- [ ] (C) Unit + integration tests passing (tools tests + controller tests)
- [ ] (D) All of the above
- [ ] (E) Other (describe)
