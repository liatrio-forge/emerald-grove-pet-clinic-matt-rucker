# 07 Tasks - UI/UX Polish

Spec: [07-spec-ui-ux-polish.md](07-spec-ui-ux-polish.md)

## Relevant Files

- `src/main/resources/templates/fragments/layout.html` — Global nav layout; add language selector dropdown
- `src/main/resources/templates/error.html` — Error template; add "Back to Find Owners" link in 404 block
- `src/main/java/org/springframework/samples/petclinic/system/GlobalExceptionHandler.java` — New `@ControllerAdvice` to catch `IllegalArgumentException` and return 404
- `src/main/resources/messages/messages*.properties` — i18n keys for language names and 404 link text
- `src/test/java/org/springframework/samples/petclinic/system/GlobalExceptionHandlerTests.java` — New tests for 404 handling
- `src/test/java/org/springframework/samples/petclinic/owner/OwnerControllerTests.java` — Verify missing owner returns 404 (may need integration test)
- `e2e-tests/tests/features/language-selector.spec.ts` — New Playwright E2E test for language switching
- `e2e-tests/tests/features/friendly-404.spec.ts` — New Playwright E2E test for 404 pages

### Notes

- The `LocaleChangeInterceptor` and `SessionLocaleResolver` are already configured in `WebConfiguration.java`
- The `error.html` template already handles 404 status with a conditional block
- `IllegalArgumentException` is thrown by `OwnerController.findOwner()`, `PetController.findPet()`, and `VisitController.loadPetWithVisit()` when IDs are not found
- Follow conventional commits, dual-loop TDD, Arrange-Act-Assert

## Tasks

### [x] 1.0 Language Selector in Header

Add a Bootstrap dropdown language selector to the navbar with all 9 available languages, using the existing `?lang=xx` mechanism.

#### 1.0 Proof Artifact(s)

- JUnit: Integration test verifying `?lang=de` changes page content to German
- Playwright: E2E test that selects a language, verifies translated text, navigates, and verifies persistence
- Screenshot: Header with language dropdown open

#### 1.0 Tasks

- [ ] 1.1 **Outer loop — write failing acceptance tests**: (a) Playwright test that opens the app, clicks the language dropdown, selects German, verifies a German text appears (e.g., heading changes), navigates to another page, verifies German persists. (b) JUnit integration test that hits a page with `?lang=de` and verifies German content in response.
- [ ] 1.2 **Add language selector dropdown to `layout.html`** — add a Bootstrap dropdown after the last nav item (far right) with all 9 languages listed by native name. Each option links to the current page with `?lang=xx`. Show the current language name as the toggle text. Highlight the active language.
- [ ] 1.3 **Add i18n keys** — add `language` key (for the dropdown label) to all `messages*.properties` files.
- [ ] 1.4 **Inner loop — run tests, verify all pass** — run `./mvnw test` and confirm all new and existing tests pass.
- [ ] 1.5 **Write Playwright E2E test** `language-selector.spec.ts` — verify dropdown is visible, select German, verify German text appears, navigate to another page, verify language persists.
- [ ] 1.6 **Capture proof artifacts** — save to `docs/specs/07-spec-ui-ux-polish/07-proofs/`.

### [ ] 2.0 Friendly 404 for Missing Owner/Pet

Add `@ControllerAdvice` to catch `IllegalArgumentException` and return 404 status. Add "Back to Find Owners" link to the 404 section of error.html.

#### 2.0 Proof Artifact(s)

- JUnit: MockMvc/integration tests verifying `/owners/9999` returns 404 status and friendly message
- Playwright: E2E test navigating to a non-existent owner URL and verifying friendly message and link

#### 2.0 Tasks

- [ ] 2.1 **Outer loop — write failing acceptance tests**: (a) `@SpringBootTest` integration test that hits `/owners/9999` and expects 404 status (currently returns 500). (b) Playwright test that navigates to non-existent owner and verifies "not found" message and "Find Owners" link.
- [ ] 2.2 **Create `GlobalExceptionHandler`** — new `@ControllerAdvice` class in the `system` package that catches `IllegalArgumentException` with `@ExceptionHandler`, sets `@ResponseStatus(HttpStatus.NOT_FOUND)`, and returns the error view.
- [ ] 2.3 **Update `error.html`** — add a "Back to Find Owners" link (styled as a button) inside the existing `th:if="${status == 404}"` block. Use i18n key for the link text.
- [ ] 2.4 **Add i18n keys** — add `backToFindOwners` key to all `messages*.properties` files.
- [ ] 2.5 **Inner loop — run tests, verify all pass** — run `./mvnw test` and confirm all new and existing tests pass. Existing CrashController tests should still pass.
- [ ] 2.6 **Write Playwright E2E test** `friendly-404.spec.ts` — navigate to `/owners/9999`, verify 404-friendly message, verify "Back to Find Owners" link works.
- [ ] 2.7 **Capture proof artifacts** — save to `docs/specs/07-spec-ui-ux-polish/07-proofs/`.
