# 04 Tasks - Vet Filtering and Pagination

Spec: [04-spec-vet-filtering-and-pagination.md](04-spec-vet-filtering-and-pagination.md)

## Relevant Files

- `src/main/java/org/springframework/samples/petclinic/vet/VetController.java` — Controller for HTML and JSON vet endpoints; add filter param handling
- `src/main/java/org/springframework/samples/petclinic/vet/VetRepository.java` — Repository interface; add filtered query methods (by specialty name, no specialty)
- `src/main/java/org/springframework/samples/petclinic/vet/SpecialtyRepository.java` — New repository to query all specialties for pill button population
- `src/main/java/org/springframework/samples/petclinic/vet/Vet.java` — Vet entity (reference only; no changes expected)
- `src/main/java/org/springframework/samples/petclinic/vet/Specialty.java` — Specialty entity (reference only; no changes expected)
- `src/main/java/org/springframework/samples/petclinic/vet/Vets.java` — Vets wrapper for JSON (reference only; no changes expected)
- `src/main/resources/templates/vets/vetList.html` — Vet Directory template; add pill buttons and fix pagination links
- `src/main/resources/messages/messages*.properties` — i18n keys for new UI text (All, None filter labels)
- `src/test/java/org/springframework/samples/petclinic/vet/VetControllerTests.java` — Unit tests for filter and pagination behavior
- `e2e-tests/tests/pages/vet-page.ts` — Playwright page object; add methods for filter pills
- `e2e-tests/tests/features/vet-filter.spec.ts` — New Playwright E2E tests for specialty filtering
- `e2e-tests/tests/features/vet-pagination-filter.spec.ts` — New Playwright E2E tests for pagination with filter

### Notes

- Unit tests use `@WebMvcTest(VetController.class)` with `@MockitoBean` for `VetRepository` and `SpecialtyRepository`
- Playwright page objects extend `BasePage` and live in `e2e-tests/tests/pages/`
- Playwright feature tests live in `e2e-tests/tests/features/`
- Run Java tests with `./mvnw test`
- Run Playwright tests with `npm test` from `e2e-tests/`
- Follow Arrange-Act-Assert pattern for all tests
- Follow conventional commits: `type(scope): description`
- Use dual-loop TDD: outer loop (acceptance tests) then inner loop (unit red-green-refactor)
- `VetRepository` extends `Repository` (not `JpaRepository`) — custom queries need `@Query` annotations

## Tasks

### [x] 1.0 Specialty Filter on Vet Directory

Add specialty filter to the Vet Directory with clickable pill buttons (All, each specialty, None), query param support (`filter`), filtered repository queries (no caching), and apply the same filter to the JSON REST endpoint. Populate specialty list from the database.

#### 1.0 Proof Artifact(s)

- JUnit: `VetControllerTests` — MockMvc tests for filter by specialty name, filter by "none", no filter (all vets), unrecognized filter graceful fallback, model contains specialty list, and JSON endpoint with filter param
- Playwright: E2E test that opens Vet Directory, verifies pill buttons are visible, clicks a specialty pill, verifies filtered results, and verifies URL contains filter param
- Screenshot: Vet Directory with specialty pill buttons and active filter highlighted

#### 1.0 Tasks

- [x] 1.1 **Outer loop — write failing acceptance tests** in `VetControllerTests`: (a) `GET /vets.html?filter=radiology` returns only vets with radiology specialty, (b) `GET /vets.html?filter=none` returns only vets with no specialty, (c) `GET /vets.html` with no filter returns all vets, (d) `GET /vets.html?filter=unknown` falls back to all vets, (e) model contains `specialties` list and `currentFilter` attribute, (f) `GET /vets?filter=radiology` JSON endpoint returns filtered vets. All tests should fail at this point.
- [x] 1.2 **Create `SpecialtyRepository`** — new interface extending `Repository<Specialty, Integer>` with a `findAll()` method returning `Collection<Specialty>` to populate the pill button list from the database.
- [x] 1.3 **Add filtered query methods to `VetRepository`** — add `@Query` methods: (a) `findBySpecialtyName(String specialtyName, Pageable pageable)` using JPQL join on specialties, returning `Page<Vet>`, and (b) `findByNoSpecialties(Pageable pageable)` for vets with empty specialty set. Neither method should have `@Cacheable`.
- [x] 1.4 **Update `VetController.showVetList`** — accept optional `filter` query param, load all specialties from `SpecialtyRepository`, apply filter logic (empty/absent → all, "none" → no-specialty query, recognized specialty → filter query, unrecognized → fallback to all), pass `specialties` list, `currentFilter`, and `filter` value to the model.
- [x] 1.5 **Update `VetController.showResourcesVetList`** — accept optional `filter` query param and apply the same filter logic to the JSON REST endpoint, returning filtered `Vets` wrapper.
- [x] 1.6 **Update `vetList.html`** — add a row of clickable pill buttons above the vet table: "All" first, then each specialty from the model alphabetically, then "None" last. Each pill links to `/vets.html?filter=<name>` ("All" links to `/vets.html` with no filter). Highlight the active pill based on `currentFilter` model attribute using a distinct CSS class.
- [x] 1.7 **Add i18n keys** — add `filterAll` and `filterNone` keys to all `messages*.properties` files for the "All" and "None" pill labels.
- [x] 1.8 **Inner loop — run tests, verify all pass** — run `./mvnw test` and confirm all new and existing tests pass. Fix any failures.
- [x] 1.9 **Write Playwright E2E test** `vet-filter.spec.ts` — test that pill buttons are visible, clicking a specialty pill filters the table, clicking "All" shows all vets, clicking "None" shows only vets without specialties, and the URL contains the filter param. Update `vet-page.ts` page object with `clickFilterPill(name)` and `activeFilterPill()` methods.
- [x] 1.10 **Capture proof artifacts** — screenshot of Vet Directory with pill buttons, save to `docs/specs/04-spec-vet-filtering-and-pagination/04-proofs/`.

### [x] 2.0 Preserve Filter Across Vet Pagination

Fix pagination links on the Vet Directory to include the active `filter` query parameter. Ensure clean URLs when no filter is active. Maintain highlighted pill state after page navigation.

#### 2.0 Proof Artifact(s)

- JUnit: `VetControllerTests` — MockMvc test verifying the model contains the filter value for pagination link construction
- Playwright: E2E test that applies a specialty filter, navigates to page 2 (if available), verifies the filter param persists in the URL and the correct pill remains highlighted

#### 2.0 Tasks

- [x] 2.1 **Outer loop — write failing acceptance test** in `VetControllerTests`: verify that when `filter=radiology` is passed, the model contains the `filter` attribute value for pagination link construction.
- [x] 2.2 **Fix pagination in `vetList.html`** — update all pagination links to conditionally include `&filter=<value>` from the model when a filter is active. When no filter is active, omit the param for clean URLs.
- [x] 2.3 **Inner loop — run tests, verify all pass** — run `./mvnw test` and confirm all new and existing tests pass.
- [x] 2.4 **Write Playwright E2E test** `vet-pagination-filter.spec.ts` — apply a filter, navigate pagination, verify filter param persists in URL and active pill remains highlighted.
- [x] 2.5 **Capture proof artifacts** — save test output to `docs/specs/04-spec-vet-filtering-and-pagination/04-proofs/`.
