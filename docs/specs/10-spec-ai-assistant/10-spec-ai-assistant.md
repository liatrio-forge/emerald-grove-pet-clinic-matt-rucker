# 10-spec-ai-assistant

## Introduction/Overview

The Emerald Grove Veterinary Clinic needs an AI-powered assistant that allows pet owners to interact with the clinic through natural language conversation. Unlike a simple chatbot, this assistant can perform real actions — searching for owners, viewing pet details, adding pets, and booking visits — through the same data layer the web UI uses. It is built with Spring AI and Anthropic Claude using tool use (function calling), where the AI model decides which application functions to invoke based on the user's request.

## Goals

- Provide pet owners with a conversational interface to perform common clinic tasks without navigating forms
- Integrate Anthropic Claude with Spring AI's tool-calling framework so the AI can invoke application functions
- Reuse the existing repository layer (no duplicated data access logic)
- Deliver a chat UI that fits the existing Liatrio dark theme design system
- Conditionally enable the feature only when an Anthropic API key is configured

## User Stories

- **As a pet owner**, I want to ask the assistant to find my account so that I can quickly check my information without navigating through search forms.
- **As a pet owner**, I want to ask the assistant to add a new pet to my account so that I can register my pet through conversation instead of filling out a form.
- **As a pet owner**, I want to ask the assistant to book a visit for my pet so that I can schedule an appointment by describing what I need in plain language.
- **As a pet owner**, I want the assistant to confirm before making any changes so that I don't accidentally create duplicate records or book wrong appointments.
- **As a pet owner**, I want the assistant to link me to relevant pages so that I can view full details in the existing app interface when needed.

## Demoable Units of Work

### Unit 1: Spring AI Integration and Read-Only Tools

**Purpose:** Establish the Spring AI + Anthropic foundation and prove the tool-calling pattern works by implementing read-only tools that query existing data.

**Functional Requirements:**
- The system shall include Spring AI 2.0.0-M4 with the Anthropic starter as a Maven dependency
- The system shall configure the Anthropic API key via `spring.ai.anthropic.api-key` property, reading from the `ANTHROPIC_API_KEY` environment variable
- The system shall configure the Claude model via `spring.ai.anthropic.chat.options.model` property, defaulting to `claude-sonnet-4-20250514`
- The system shall provide a `searchOwners` tool that accepts optional lastName, telephone, and city parameters and returns matching owners using `OwnerRepository.searchOwners()`
- The system shall provide a `getOwnerDetails` tool that accepts an owner ID and returns the owner's full information including pets and visit history, with a link to `/owners/{id}`
- The system shall provide a `listVets` tool that returns all veterinarians with their specialties
- The system shall provide a `findVetsBySpecialty` tool that accepts a specialty name and returns matching vets
- The system shall provide a `listPetTypes` tool that returns all valid pet types
- The system shall provide a `getUpcomingVisits` tool that accepts a number of days and returns visits within that date range
- All tools shall return formatted String results (not JPA entities) to avoid circular reference serialization issues

**Proof Artifacts:**
- Test: `AssistantToolsTests` — unit tests for all read-only tools with mocked repositories pass
- Test: Application compiles and starts with `./mvnw spring-boot:run` when `ANTHROPIC_API_KEY` is set

### Unit 2: Write Tools with Confirmation

**Purpose:** Add tools that create and modify data, with the system prompt instructing Claude to always confirm before executing write operations.

**Functional Requirements:**
- The system shall provide a `createOwner` tool that accepts firstName, lastName, address, city, and telephone, validates the telephone is exactly 10 digits, and creates a new owner via `OwnerRepository.save()`
- The system shall provide an `addPetToOwner` tool that accepts ownerId, petName, petTypeName, and birthDate (yyyy-MM-dd), looks up the pet type by name from `PetTypeRepository.findPetTypes()`, and adds the pet via `owner.addPet(pet)` then `OwnerRepository.save(owner)`
- The system shall provide a `bookVisit` tool that accepts ownerId, petId, date (yyyy-MM-dd), and description, validates the date is today or in the future, and creates the visit via `owner.addVisit(petId, visit)` then `OwnerRepository.save(owner)`
- Write tools shall return clear error messages (not exceptions) for validation failures such as invalid date format, unknown pet type, owner not found, or pet not found
- The system prompt shall instruct Claude to always describe the intended action and ask the user for confirmation before calling any write tool

**Proof Artifacts:**
- Test: `AssistantToolsTests` — unit tests for all write tools including validation edge cases pass
- Test: Full test suite passes with `./mvnw test`

### Unit 3: Chat Controller, UI, and Navigation

**Purpose:** Deliver a persistent chat widget that floats on every page, allowing pet owners to interact with the assistant while navigating the site.

**Functional Requirements:**
- The system shall expose a `POST /api/assistant/chat` endpoint that accepts a JSON body with a `message` field and returns a JSON response with a `response` field
- The system shall expose a `GET /api/assistant/history` endpoint that returns the current session's conversation history as JSON, so the widget can restore messages after page navigation
- The system shall maintain conversation history per HTTP session in memory, capped at 20 messages to limit token usage
- The chat widget shall be embedded in the shared layout fragment (`fragments/layout.html`) so it appears on every page
- The chat widget shall be a floating panel in the bottom-right corner of the screen, toggled open/closed by a floating action button (FAB)
- The widget shall preserve its open/closed state across page navigations using `sessionStorage`
- The widget shall restore conversation messages after page navigation by fetching from the history endpoint
- The chat widget shall display messages in a scrollable container with visually distinct user and assistant message bubbles
- The chat widget shall include a text input and send button, with the send button triggering a POST to the chat API via JavaScript fetch
- The chat widget shall show a loading indicator while waiting for the assistant's response
- The chat widget shall render links in assistant responses as clickable HTML links
- The chat widget (FAB and panel) shall only be visible when the Anthropic API key is configured
- The chat widget shall follow the Liatrio dark theme design system (colors, typography, spacing, border radius per `docs/STYLE_GUIDE.md`)
- The chat widget shall be built using the `frontend-design` skill and audited with the `web-design-guidelines` skill for accessibility compliance

**Proof Artifacts:**
- Test: `AssistantControllerTests` — WebMvcTest verifying POST /api/assistant/chat returns JSON and GET /api/assistant/history returns conversation array
- Test: Playwright E2E test that opens the chat widget on any page, sends a message, verifies a response appears, navigates to another page, and verifies the widget and conversation persist
- Screenshot: Chat widget open on a page, demonstrating visual compliance with STYLE_GUIDE.md

## Non-Goals (Out of Scope)

1. **Authentication and authorization** — there is no login system; the assistant does not restrict access to specific owners' data
2. **Persistent conversation history** — conversations are lost when the HTTP session expires; no database storage of chat history
3. **Streaming responses** — the initial implementation uses simple request/response; streaming (SSE) is a future enhancement
4. **WebSocket support** — not needed for synchronous request/response chat
5. **External memory service (Honcho)** — conversations are short and task-oriented; in-memory history is sufficient
6. **Vet assignment for visits** — the existing visit model does not assign a specific vet; the assistant follows the same constraint
7. **File uploads or image analysis** — text-only conversation

## Design Considerations

The chat UI is a persistent floating widget embedded in the shared layout fragment (`fragments/layout.html`), visible on every page.

**Widget structure:**
- A floating action button (FAB) in the bottom-right corner toggles the chat panel open/closed
- FAB uses the `fa-comments` icon, styled with `#24AE1D` green background
- The chat panel is a fixed-position drawer (~350px wide, ~450px tall) anchored to the bottom-right
- Panel contains: header bar with title + close button, scrollable message area, input row at the bottom
- The widget and FAB are hidden entirely when no API key is configured (controlled via a Thymeleaf `th:if` on a model attribute)

**Message display:**
- Assistant messages left-aligned with dark background (`#111111`)
- User messages right-aligned with green-tinted background (`#24AE1D` at low opacity)
- Loading indicator (animated dots) while waiting for response

**State persistence across navigation:**
- Widget open/closed state stored in `sessionStorage`
- On page load, JavaScript fetches `GET /api/assistant/history` to restore displayed messages
- Input field content is not preserved (acceptable — messages are short)

**Colors and typography** must follow `docs/STYLE_GUIDE.md`:
- Panel: `#1E2327` background, `#333333` border, `16px` radius
- Header: `#111111` background
- Text: `#f8f9fa` primary, `#cccccc` secondary
- Links in responses: `#89df00` (lime accent)
- Input: `#111111` background, `#333333` border, `#24AE1D` focus ring
- Font: DM Sans (inherited from layout)

## Repository Standards

- **Architecture:** Layered (Presentation -> Business -> Data). The assistant tools wrap the repository layer; the controller handles HTTP.
- **Save pattern:** Pets and visits are persisted via Owner cascade (`owner.addPet()`/`owner.addVisit()` then `owners.save(owner)`), not saved directly.
- **Testing:** `@WebMvcTest` for controllers with `@MockitoBean`. `@ExtendWith(MockitoExtension.class)` for unit tests. BDD-style mocking with `given().willReturn()`. Arrange-Act-Assert pattern.
- **Formatting:** Spring Java Format (`spring-javaformat-maven-plugin`). Run `./mvnw spring-javaformat:apply` before committing.
- **Checkstyle:** nohttp check — all URLs in code must use `https://`.
- **Commits:** Conventional commits format (`feat(assistant): ...`).
- **Branching:** Feature branch `feat/ai-assistant`, never commit to main directly.
- **i18n:** All user-facing text in `messages*.properties` files.

## Technical Considerations

- **Spring AI 2.0.0-M4** is a milestone release targeting Spring Boot 4.0. It requires the Spring Milestones repository (`https://repo.spring.io/milestone`) in pom.xml since it is not in Maven Central.
- **Dependency:** `spring-ai-starter-model-anthropic` (version managed by Spring AI BOM `spring-ai-bom:2.0.0-M4`).
- **Tool return type:** All `@Tool` methods must return `String` to avoid JPA entity serialization issues (circular refs between Owner <-> Pet <-> Visit).
- **Conversation cap:** 20 messages max per session to keep token usage reasonable. System prompt + 20 messages + tool results should stay well within Claude's context window.
- **Conditional feature:** The chat widget visibility should be controlled by checking if the `spring.ai.anthropic.api-key` property is set (via a `@ControllerAdvice` exposing a model attribute).
- **API key not in source:** The API key comes from the `ANTHROPIC_API_KEY` environment variable. Never hard-code it.

## Security Considerations

- **API key handling:** The Anthropic API key is loaded from an environment variable (`ANTHROPIC_API_KEY`), never committed to source control. The `application.properties` file uses `${ANTHROPIC_API_KEY:}` placeholder syntax.
- **No authentication:** The assistant has unrestricted read/write access to all clinic data. This is acceptable for a learning exercise but would require authentication in production.
- **Input validation:** Write tools must validate inputs (telephone format, date format, pet type existence) before persisting to prevent bad data.
- **Proof artifacts:** E2E tests must not contain or log API keys. Tests that require a live API key should be skipped in CI when the key is not set.

## Success Metrics

1. **All read tools functional** — assistant can search owners, view details, list vets, list pet types, check upcoming visits
2. **All write tools functional** — assistant can create owners, add pets, book visits with confirmation
3. **Playwright E2E test passes** — automated test sends a message and verifies a response
4. **Full test suite passes** — `./mvnw test` passes including new assistant tests
5. **UI matches design system** — chat page follows Liatrio dark theme per STYLE_GUIDE.md

## Open Questions

No open questions at this time.
