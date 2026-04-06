# 10-tasks-ai-assistant

## Relevant Files

### New Files

- `src/main/java/org/springframework/samples/petclinic/assistant/AssistantTools.java` - `@Component` with `@Tool`-annotated methods wrapping existing repositories
- `src/main/java/org/springframework/samples/petclinic/assistant/AssistantConfiguration.java` - `@Configuration` producing `ChatClient` bean with system prompt and tools
- `src/main/java/org/springframework/samples/petclinic/assistant/AssistantController.java` - `@RestController` with POST /api/assistant/chat and GET /api/assistant/history endpoints
- `src/main/java/org/springframework/samples/petclinic/assistant/AssistantAvailabilityAdvice.java` - `@ControllerAdvice` exposing `assistantEnabled` model attribute for conditional widget rendering
- `src/main/resources/templates/fragments/chat-widget.html` - Thymeleaf fragment for the floating chat widget (FAB + panel + inline JS)
- `src/test/java/org/springframework/samples/petclinic/assistant/AssistantToolsTests.java` - Unit tests for all tool methods with mocked repositories
- `src/test/java/org/springframework/samples/petclinic/assistant/AssistantControllerTests.java` - WebMvcTest for REST endpoints
- `e2e-tests/tests/features/ai-assistant.spec.ts` - Playwright E2E test for chat widget functionality

### Modified Files

- `pom.xml` - Add Spring AI BOM, `spring-ai-starter-model-anthropic`, Spring Milestones repository
- `src/main/resources/application.properties` - Add `spring.ai.anthropic.*` configuration properties
- `src/main/resources/templates/fragments/layout.html` - Include chat widget fragment (conditional on `assistantEnabled`)
- `src/main/resources/static/resources/css/petclinic.css` - Add chat widget styles (FAB, panel, bubbles, loading indicator)

### Reference Files (read-only, patterns to follow)

- `src/main/java/org/springframework/samples/petclinic/owner/OwnerRepository.java` - `searchOwners()` method used by tools
- `src/main/java/org/springframework/samples/petclinic/owner/VisitController.java` - Visit save pattern: `owner.addVisit()` then `owners.save(owner)`
- `src/main/java/org/springframework/samples/petclinic/owner/PetController.java` - Pet save pattern: `owner.addPet()` then `owners.save(owner)`
- `src/main/java/org/springframework/samples/petclinic/owner/PetTypeRepository.java` - `findPetTypes()` method
- `src/main/java/org/springframework/samples/petclinic/vet/VetRepository.java` - `findBySpecialtyName()` method
- `src/main/java/org/springframework/samples/petclinic/owner/VisitRepository.java` - `findUpcomingVisits()` method
- `src/test/java/org/springframework/samples/petclinic/vet/VetControllerTests.java` - Test pattern reference (`@WebMvcTest`, `@MockitoBean`, BDD-style)
- `e2e-tests/tests/features/owner-management.spec.ts` - E2E test pattern reference (page objects, fixtures)
- `docs/STYLE_GUIDE.md` - Liatrio dark theme design tokens

### Notes

- Unit tests are placed in a mirrored package structure under `src/test/java/`
- Run tests with `./mvnw test` or target specific tests with `./mvnw test -Dtest=AssistantToolsTests`
- Run Spring Java Format before committing: `./mvnw spring-javaformat:apply`
- E2E tests use `@fixtures/base-test` and page objects from `@pages/`
- The nohttp checkstyle check requires all URLs in source code use `https://`
- Pets and visits persist via Owner cascade — never save them directly

## Tasks

### [x] 1.0 Spring AI Foundation and Configuration

Set up the Spring AI 2.0.0-M4 dependency with Anthropic starter, configure the API key and model properties, and verify the application compiles and starts.

#### 1.0 Proof Artifact(s)

- CLI: `./mvnw compile` succeeds with Spring AI dependencies resolved demonstrates dependency configuration is correct
- CLI: Application starts with `ANTHROPIC_API_KEY` set and logs show Spring AI auto-configuration demonstrates integration is wired

#### 1.0 Tasks

- [x] 1.1 Add `<spring-ai.version>2.0.0-M4</spring-ai.version>` property to the `<properties>` section in `pom.xml`
- [x] 1.2 Add a `<dependencyManagement>` section to `pom.xml` (before `<dependencies>`) importing the Spring AI BOM: `spring-ai-bom` with version `${spring-ai.version}`, type `pom`, scope `import`
- [x] 1.3 Add the `spring-ai-starter-model-anthropic` dependency to the `<dependencies>` section (no version needed — managed by BOM)
- [x] 1.4 Add a `<repositories>` section to `pom.xml` (before `<build>`) with the Spring Milestones repository: id `spring-milestones`, url `https://repo.spring.io/milestone`, snapshots disabled
- [x] 1.5 Add Anthropic configuration to `application.properties`: `spring.ai.anthropic.api-key=${ANTHROPIC_API_KEY:}` and `spring.ai.anthropic.chat.options.model=claude-sonnet-4-20250514` and `spring.ai.anthropic.chat.options.max-tokens=1024`
- [x] 1.6 Run `./mvnw compile` and verify it succeeds with all dependencies resolved
- [x] 1.7 Run `./mvnw spring-javaformat:apply` to ensure formatting compliance

### [x] 2.0 Read-Only Assistant Tools with Unit Tests

Implement the 6 read-only `@Tool` methods in `AssistantTools.java` and the `ChatClient` configuration in `AssistantConfiguration.java`. All tools return formatted Strings and are tested with mocked repositories following TDD.

#### 2.0 Proof Artifact(s)

- Test: `AssistantToolsTests` passes — unit tests for all 6 read-only tools with mocked repositories demonstrates tools correctly query data and format results
- CLI: `./mvnw test -Dtest=AssistantToolsTests` exits with BUILD SUCCESS

#### 2.0 Tasks

- [x] 2.1 Create `AssistantTools.java` as a `@Component` in `src/main/java/.../assistant/` with constructor injection of `OwnerRepository`, `VetRepository`, `VisitRepository`, and `PetTypeRepository`
- [x] 2.2 Write a failing test for `searchOwners` tool: mock `OwnerRepository.searchOwners()` returning a page of owners, verify the tool returns a formatted string with owner names and IDs
- [x] 2.3 Implement the `searchOwners` `@Tool` method: accept optional `lastName`, `telephone`, `city` parameters (empty string = any), call `OwnerRepository.searchOwners()` with `PageRequest.of(0, 10)`, return formatted string with name, city, telephone, and link `/owners/{id}` for each result
- [x] 2.4 Write a failing test for `getOwnerDetails` tool: mock `OwnerRepository.findById()` returning an owner with pets and visits, verify the tool returns formatted details including pet names, types, and visit dates
- [x] 2.5 Implement the `getOwnerDetails` `@Tool` method: accept `ownerId`, call `OwnerRepository.findById()`, return formatted string with owner info, each pet (name, type, birth date), each pet's visits (date, description), and link to `/owners/{id}`. Return "Owner not found" if not present.
- [x] 2.6 Write a failing test for `listVets` tool: mock `VetRepository.findAll()` returning vets with specialties, verify formatted output
- [x] 2.7 Implement the `listVets` `@Tool` method: call `VetRepository.findAll()`, return formatted string listing each vet with their specialties
- [x] 2.8 Write a failing test for `findVetsBySpecialty` tool: mock `VetRepository.findBySpecialtyName()`, verify filtered results
- [x] 2.9 Implement the `findVetsBySpecialty` `@Tool` method: accept `specialtyName`, call `VetRepository.findBySpecialtyName()`, return formatted results
- [x] 2.10 Write a failing test for `listPetTypes` tool: mock `PetTypeRepository.findPetTypes()`, verify formatted list
- [x] 2.11 Implement the `listPetTypes` `@Tool` method: call `PetTypeRepository.findPetTypes()`, return formatted list of type names
- [x] 2.12 Write a failing test for `getUpcomingVisits` tool: mock `VisitRepository.findUpcomingVisits()`, verify formatted visit list with pet and owner info
- [x] 2.13 Implement the `getUpcomingVisits` `@Tool` method: accept `days` parameter, calculate date range from today, call `VisitRepository.findUpcomingVisits()` with `PageRequest.of(0, 20)`, return formatted list
- [x] 2.14 Create `AssistantConfiguration.java` as a `@Configuration` class that produces a `ChatClient` bean using `ChatClient.Builder`, set the system prompt (pet-owner-facing, friendly tone, include confirmation instruction for future write tools), and register `AssistantTools` via `.defaultTools()`
- [x] 2.15 Run `./mvnw test -Dtest=AssistantToolsTests` and verify all read-tool tests pass
- [x] 2.16 Run `./mvnw spring-javaformat:apply` to ensure formatting compliance

### [ ] 3.0 Write Tools with Confirmation and Validation

Implement the 3 write `@Tool` methods (`createOwner`, `addPetToOwner`, `bookVisit`) with input validation and error messages. Test all write tools including edge cases.

#### 3.0 Proof Artifact(s)

- Test: `AssistantToolsTests` passes — unit tests for all 9 tools (6 read + 3 write) including validation edge cases demonstrates complete tool coverage
- CLI: `./mvnw test` full suite passes with no regressions demonstrates write tools integrate cleanly

#### 3.0 Tasks

- [ ] 3.1 Write a failing test for `createOwner` happy path: verify it calls `OwnerRepository.save()` with correct fields and returns success message with link to new owner
- [ ] 3.2 Write a failing test for `createOwner` validation: verify it returns an error message when telephone is not exactly 10 digits
- [ ] 3.3 Implement the `createOwner` `@Tool` method: accept `firstName`, `lastName`, `address`, `city`, `telephone`; validate telephone is 10 digits; create and save Owner; return success message with link `/owners/{id}`
- [ ] 3.4 Write a failing test for `addPetToOwner` happy path: mock owner lookup and pet type lookup, verify `owner.addPet()` is called and owner is saved
- [ ] 3.5 Write failing tests for `addPetToOwner` edge cases: owner not found, unknown pet type name, invalid date format
- [ ] 3.6 Implement the `addPetToOwner` `@Tool` method: accept `ownerId`, `petName`, `petTypeName`, `birthDate` (yyyy-MM-dd); look up owner and pet type; validate inputs; call `owner.addPet(pet)` then `owners.save(owner)`; return success or error message
- [ ] 3.7 Write a failing test for `bookVisit` happy path: mock owner lookup, verify visit is created with correct date and description
- [ ] 3.8 Write failing tests for `bookVisit` edge cases: owner not found, pet not found on owner, date in the past, invalid date format
- [ ] 3.9 Implement the `bookVisit` `@Tool` method: accept `ownerId`, `petId`, `date` (yyyy-MM-dd), `description`; look up owner and pet; validate date is today or future; call `owner.addVisit(petId, visit)` then `owners.save(owner)`; return success or error message
- [ ] 3.10 Run `./mvnw test` and verify the full test suite passes (including all existing tests)
- [ ] 3.11 Run `./mvnw spring-javaformat:apply` to ensure formatting compliance

### [ ] 4.0 Chat Widget, Controller, and E2E Test

Build the `AssistantController` REST endpoints, the persistent floating chat widget embedded in the site layout, and a Playwright E2E test verifying cross-page persistence.

#### 4.0 Proof Artifact(s)

- Test: `AssistantControllerTests` passes — WebMvcTest verifying POST /api/assistant/chat returns JSON and GET /api/assistant/history returns conversation array demonstrates REST endpoints work
- Test: Playwright E2E test passes — opens chat widget, sends a message, verifies response, navigates to another page, verifies widget and conversation persist demonstrates end-to-end cross-page functionality
- Screenshot: Chat widget open on a page demonstrates visual compliance with STYLE_GUIDE.md
- CLI: `./mvnw test` full suite passes demonstrates no regressions

#### 4.0 Tasks

- [ ] 4.1 Write a failing `AssistantControllerTests` test: `POST /api/assistant/chat` with JSON `{"message": "hello"}` returns 200 with JSON containing a `response` field. Use `@WebMvcTest(AssistantController.class)` with `@MockitoBean` for `ChatClient`.
- [ ] 4.2 Write a failing `AssistantControllerTests` test: `GET /api/assistant/history` returns 200 with a JSON array
- [ ] 4.3 Write a failing `AssistantControllerTests` test: `POST /api/assistant/chat` returns a friendly error JSON (not a stack trace) when `ChatClient` throws an exception
- [ ] 4.4 Create `AssistantController.java` as a `@RestController`: implement `POST /api/assistant/chat` accepting JSON body, calling `ChatClient`, returning JSON response; implement `GET /api/assistant/history` returning the current session's conversation as a JSON array of `{role, content}` objects. Maintain conversation history in a `ConcurrentHashMap<String, List<Message>>` keyed by `HttpSession.getId()`, capped at 20 messages. Wrap `ChatClient` call in try-catch returning friendly error on failure.
- [ ] 4.5 Make the controller tests pass, run `./mvnw test -Dtest=AssistantControllerTests`
- [ ] 4.6 Create `AssistantAvailabilityAdvice.java` as a `@ControllerAdvice` that exposes an `assistantEnabled` boolean model attribute (`true` when `spring.ai.anthropic.api-key` property is non-empty, using `@Value`)
- [ ] 4.7 Use `frontend-design` skill to build the chat widget fragment: Create `src/main/resources/templates/fragments/chat-widget.html` containing the FAB button (`fa-comments` icon, bottom-right, `#24AE1D` background), the chat panel (~350px wide, ~450px tall, fixed bottom-right), header bar with title + close button, scrollable message area, text input + send button, and inline JavaScript handling: toggle open/close, persist open/closed state in `sessionStorage`, fetch `/api/assistant/history` on page load to restore messages, POST to `/api/assistant/chat` on send, render responses with loading indicator, parse links in responses as clickable HTML
- [ ] 4.8 Add chat widget styles to `src/main/resources/static/resources/css/petclinic.css`: FAB button, chat panel, header bar, message bubbles (user right-aligned green-tinted, assistant left-aligned dark), input row, loading indicator, open/close transitions. Follow STYLE_GUIDE.md colors (`#111111`, `#1E2327`, `#333333`, `#f8f9fa`, `#89df00`, `#24AE1D`)
- [ ] 4.9 Include the chat widget fragment in `src/main/resources/templates/fragments/layout.html`: add `th:replace` for the chat widget fragment wrapped in `th:if="${assistantEnabled}"`, placed before the closing `</body>` tag
- [ ] 4.10 Run `web-design-guidelines` skill to audit the chat widget for accessibility compliance (WCAG AA contrast, focus-visible states, semantic HTML, aria labels on FAB and close button)
- [ ] 4.11 Create `e2e-tests/tests/features/ai-assistant.spec.ts`: Playwright test that (1) clicks the FAB to open the widget on any page, (2) types a message and sends it, (3) verifies a response appears in the widget, (4) navigates to a different page, (5) verifies the widget is still open and conversation messages are preserved. Use `@fixtures/base-test` pattern. Skip if `ANTHROPIC_API_KEY` env var is not set.
- [ ] 4.12 Run `./mvnw test` to verify full Java test suite passes
- [ ] 4.13 Run the Playwright E2E test with `ANTHROPIC_API_KEY` set and verify it passes
- [ ] 4.14 Run `./mvnw spring-javaformat:apply` to ensure formatting compliance
