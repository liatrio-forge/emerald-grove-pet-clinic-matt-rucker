# 05 Tasks - Visit Management

Spec: [05-spec-visit-management.md](05-spec-visit-management.md)

## Relevant Files

- `src/main/java/org/springframework/samples/petclinic/owner/Visit.java` — Visit entity; add `@FutureOrPresent` on date, add `@ManyToOne Pet` relationship
- `src/main/java/org/springframework/samples/petclinic/owner/Pet.java` — Pet entity; reference for Visit relationship (may need minor adjustment)
- `src/main/java/org/springframework/samples/petclinic/owner/VisitController.java` — Existing visit creation controller (reference only for Task 1)
- `src/main/java/org/springframework/samples/petclinic/owner/VisitRepository.java` — New repository for date-range visit queries
- `src/main/java/org/springframework/samples/petclinic/owner/UpcomingVisitsController.java` — New controller for `/visits/upcoming` endpoint
- `src/main/resources/templates/pets/createOrUpdateVisitForm.html` — Visit form template (reference; no changes expected since validation errors display automatically)
- `src/main/resources/templates/visits/upcomingVisits.html` — New template for Upcoming Visits page
- `src/main/resources/templates/fragments/layout.html` — Nav layout; add Upcoming Visits menu item
- `src/main/resources/messages/messages*.properties` — i18n keys for nav item, empty state, page title
- `src/test/java/org/springframework/samples/petclinic/owner/VisitControllerTests.java` — Existing tests; add past-date validation tests
- `src/test/java/org/springframework/samples/petclinic/owner/UpcomingVisitsControllerTests.java` — New tests for upcoming visits controller
- `e2e-tests/tests/pages/visit-page.ts` — Playwright page object (may need updates)
- `e2e-tests/tests/features/visit-date-validation.spec.ts` — New Playwright E2E test for date validation
- `e2e-tests/tests/features/upcoming-visits.spec.ts` — New Playwright E2E test for upcoming visits page

### Notes

- Unit tests use `@WebMvcTest` with `@MockitoBean`; Arrange-Act-Assert pattern
- Playwright page objects extend `BasePage` and live in `e2e-tests/tests/pages/`
- Run Java tests with `./mvnw test`
- Run Playwright tests with `npm test` from `e2e-tests/`
- Follow conventional commits: `type(scope): description`
- Use dual-loop TDD: outer loop (acceptance tests) then inner loop (unit red-green-refactor)
- Visit has no existing repository — persistence is via Owner cascade. The new `VisitRepository` is read-only (for queries only)
- Adding `@ManyToOne Pet` to Visit is a schema-compatible change since the `pet_id` FK column already exists

## Tasks

### [x] 1.0 Disallow Scheduling Visits in the Past

Add `@FutureOrPresent` validation to the `Visit.date` field so that past dates are rejected with a clear error message. Verify today and future dates still work.

#### 1.0 Proof Artifact(s)

- JUnit: `VisitControllerTests` — MockMvc tests for past date rejection, today acceptance, future date acceptance
- Playwright: E2E test that attempts a past date and verifies the validation error message appears

#### 1.0 Tasks

- [x] 1.1 **Outer loop — write failing acceptance tests** in `VisitControllerTests`: (a) submit visit with past date is rejected with validation error on `date` field, (b) submit visit with today's date succeeds (3xx redirect), (c) submit visit with future date succeeds. All tests should fail at this point.
- [x] 1.2 **Add `@FutureOrPresent` annotation** to the `date` field in `Visit.java`. Import `jakarta.validation.constraints.FutureOrPresent`.
- [x] 1.3 **Inner loop — run tests, verify all pass** — run `./mvnw test` and confirm all new and existing tests pass. Fix any failures.
- [x] 1.4 **Write Playwright E2E test** `visit-date-validation.spec.ts` — navigate to a pet's visit form, enter a past date with valid description, submit, verify the form stays with a validation error message. Then enter today's date, submit, verify redirect to owner details.
- [x] 1.5 **Capture proof artifacts** — save test output to `docs/specs/05-spec-visit-management/05-proofs/`.

### [ ] 2.0 Upcoming Visits Page

Create a new read-only page at `/visits/upcoming` showing visits within the next N days (default 7). Add `VisitRepository` with date-range query, add `@ManyToOne Pet` to Visit entity, add nav item, paginate results with `days` param preserved across pages.

#### 2.0 Proof Artifact(s)

- JUnit: `UpcomingVisitsControllerTests` — MockMvc tests for default 7-day window, custom days parameter, empty result set, pagination with days preserved, invalid days fallback
- Playwright: E2E test that creates a visit for today, navigates to Upcoming Visits, and verifies the visit appears with correct owner/pet/date/description
- Screenshot: Upcoming Visits page showing visits table and nav item

#### 2.0 Tasks

- [ ] 2.1 **Outer loop — write failing acceptance tests** in new `UpcomingVisitsControllerTests`: (a) `GET /visits/upcoming` returns OK with default 7-day window and model contains `listVisits`, (b) `GET /visits/upcoming?days=14` uses custom window, (c) empty result set shows view with empty list, (d) model contains `days` attribute for pagination, (e) `GET /visits/upcoming?days=-1` falls back to default 7, (f) results are sorted by date ascending. All tests should fail.
- [ ] 2.2 **Add `@ManyToOne Pet` relationship to `Visit.java`** — add a `pet` field with `@ManyToOne` and `@JoinColumn(name = "pet_id", insertable = false, updatable = false)` to avoid conflict with the existing Pet→Visit cascade. Add getter.
- [ ] 2.3 **Create `VisitRepository`** — new interface extending `Repository<Visit, Integer>` with a `@Query` method `findUpcomingVisits(LocalDate start, LocalDate end, Pageable pageable)` that returns `Page<Visit>` joining through Pet to eager-fetch pet and owner data, sorted by date ascending.
- [ ] 2.4 **Create `UpcomingVisitsController`** — new controller in the `owner` package handling `GET /visits/upcoming`. Accept optional `days` param (default 7, validate as positive integer with fallback), query `VisitRepository`, and pass results to the model with pagination attributes and the `days` value.
- [ ] 2.5 **Create `upcomingVisits.html` template** — new Thymeleaf template displaying a table with columns: Date, Pet, Owner, Description. Show friendly "No upcoming visits scheduled" message when list is empty. Add pagination links that preserve the `days` parameter.
- [ ] 2.6 **Add nav item to `layout.html`** — add an "Upcoming Visits" menu item between "Find Owners" and "Veterinarians" using the existing `menuItem` fragment pattern with a calendar icon (`fa fa-calendar`).
- [ ] 2.7 **Add i18n keys** — add `upcomingVisits`, `noUpcomingVisits`, and any other new user-facing text keys to all `messages*.properties` files.
- [ ] 2.8 **Inner loop — run tests, verify all pass** — run `./mvnw test` and confirm all new and existing tests pass.
- [ ] 2.9 **Write Playwright E2E test** `upcoming-visits.spec.ts` — create a visit for today via the existing pet visit form, navigate to Upcoming Visits via the nav, verify the visit appears in the table with correct data. Create a page object for the upcoming visits page.
- [ ] 2.10 **Capture proof artifacts** — save test output and screenshot to `docs/specs/05-spec-visit-management/05-proofs/`.
