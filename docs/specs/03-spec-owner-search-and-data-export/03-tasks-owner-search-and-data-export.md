# 03 Tasks - Owner Search and Data Export

Spec: [03-spec-owner-search-and-data-export.md](03-spec-owner-search-and-data-export.md)

## Relevant Files

- `src/main/java/org/springframework/samples/petclinic/owner/OwnerController.java` — Controller handling search, create, update, and the new CSV export endpoint
- `src/main/java/org/springframework/samples/petclinic/owner/OwnerRepository.java` — Repository interface; needs multi-field search query and duplicate-check query
- `src/main/java/org/springframework/samples/petclinic/owner/Owner.java` — Owner entity (reference only; no changes expected)
- `src/main/java/org/springframework/samples/petclinic/model/Person.java` — Base class with firstName/lastName (reference only)
- `src/main/resources/templates/owners/findOwners.html` — Find Owners form; add telephone and city fields
- `src/main/resources/templates/owners/ownersList.html` — Search results table; fix pagination links and add CSV export button
- `src/main/resources/templates/owners/createOrUpdateOwnerForm.html` — Owner form; add global error display for duplicate detection
- `src/test/java/org/springframework/samples/petclinic/owner/OwnerControllerTests.java` — Unit tests for all new controller behavior
- `e2e-tests/tests/pages/owner-page.ts` — Playwright page object; add methods for new search fields and CSV button
- `e2e-tests/tests/features/owner-search-extended.spec.ts` — New Playwright E2E tests for extended search
- `e2e-tests/tests/features/owner-duplicate-detection.spec.ts` — New Playwright E2E tests for duplicate detection
- `e2e-tests/tests/features/owner-csv-export.spec.ts` — New Playwright E2E tests for CSV export

### Notes

- Unit tests use `@WebMvcTest(OwnerController.class)` with `@MockitoBean` for `OwnerRepository`
- Playwright page objects extend `BasePage` and live in `e2e-tests/tests/pages/`
- Playwright feature tests live in `e2e-tests/tests/features/`
- Run Java tests with `./mvnw test`
- Run Playwright tests with `npm test` from `e2e-tests/`
- Follow Arrange-Act-Assert pattern for all tests
- Follow conventional commits: `type(scope): description`
- Use dual-loop TDD: outer loop (acceptance tests) then inner loop (unit red-green-refactor)

## Tasks

### [x] 1.0 Extended Owner Search with Multi-Field Filtering

Extend the Find Owners flow to support searching by any combination of lastName, telephone, and city (AND logic, all optional). Fix pagination to preserve all search parameters across page navigation. Pre-fill form fields with active filters when displaying results.

#### 1.0 Proof Artifact(s)

- JUnit: `OwnerControllerTests` — MockMvc tests for multi-field search (lastName + city, telephone only, all three fields), single-result redirect, no-results error, telephone validation error, and pagination with preserved query params
- Playwright: E2E test that creates an owner, searches by telephone, verifies the owner appears in results, navigates pagination forward/back and verifies filter params persist in the URL
- Screenshot: Updated Find Owners form showing the three search fields

#### 1.0 Tasks

- [x] 1.1 **Outer loop — write failing acceptance tests** in `OwnerControllerTests`: (a) search by lastName + city returns filtered results, (b) search by telephone only returns matching owner, (c) search with all three fields, (d) empty fields are ignored (broadest search), (e) telephone validation error when invalid format provided, (f) single-result redirect still works with new params, (g) no-results returns to find form with error. All tests should fail at this point.
- [x] 1.2 **Add multi-field search repository method** to `OwnerRepository` — add a custom `@Query` method (JPQL) that accepts optional `lastName`, `telephone`, and `city` params with AND logic, starts-with matching, and case-insensitive comparison. Return `Page<Owner>`.
- [x] 1.3 **Update `OwnerController.processFindForm`** — accept `telephone` and `city` as `@RequestParam` (optional), validate telephone format (10 digits) if provided, call the new repository method instead of `findByLastNameStartingWith`, pass filter values to the model for template pre-fill and pagination.
- [x] 1.4 **Update `findOwners.html`** — add `telephone` and `city` input fields below `lastName`, pre-fill with current search values using `th:value`, maintain existing form layout.
- [x] 1.5 **Fix pagination in `ownersList.html`** — update all pagination links to include `lastName`, `telephone`, and `city` query params from the model so filters persist across pages.
- [x] 1.6 **Inner loop — run tests, verify all pass** — run `./mvnw test` and confirm all new and existing tests pass. Fix any failures.
- [x] 1.7 **Write Playwright E2E test** `owner-search-extended.spec.ts` — test that searches by telephone find the correct owner, test that pagination preserves filter params in the URL, update `owner-page.ts` page object with `searchByTelephone()` and `searchByCity()` methods.
- [x] 1.8 **Capture proof artifacts** — screenshot of updated Find Owners form, save to `docs/specs/03-spec-owner-search-and-data-export/03-proofs/`.

### [x] 2.0 Duplicate Owner Detection on Create and Update

Add duplicate detection to the owner creation and update flows. A duplicate is defined as an existing owner with the same firstName + lastName + telephone (case-insensitive). Display a clear global form error when a duplicate is detected. Exclude the current owner from the check during updates.

#### 2.0 Proof Artifact(s)

- JUnit: `OwnerControllerTests` — MockMvc tests for duplicate detection on create (blocked), duplicate detection on update excluding self (allowed when unchanged, blocked when matching another), and successful save when no duplicate
- Playwright: E2E test that creates an owner, attempts to create the same owner again, and verifies the error message is displayed without creating a second record

#### 2.0 Tasks

- [x] 2.1 **Outer loop — write failing acceptance tests** in `OwnerControllerTests`: (a) create owner with duplicate firstName+lastName+telephone is rejected with global error, (b) create owner with different telephone succeeds, (c) update owner to match another owner's firstName+lastName+telephone is rejected, (d) update owner without changing fields succeeds (self-exclusion), (e) verify the error message text is user-friendly.
- [x] 2.2 **Add duplicate-check repository method** to `OwnerRepository` — add a method to find owners by firstName + lastName + telephone with case-insensitive exact matching (e.g., `@Query` or derived method `findByFirstNameIgnoreCaseAndLastNameIgnoreCaseAndTelephoneIgnoreCase`). Return `Optional<Owner>` or `List<Owner>`.
- [x] 2.3 **Add duplicate detection to `OwnerController.processCreationForm`** — after Bean Validation passes, call the duplicate-check method. If a match exists, reject with a global `BindingResult` error and return the form view.
- [x] 2.4 **Add duplicate detection to `OwnerController.processUpdateOwnerForm`** — after Bean Validation passes, call the duplicate-check method. If a match exists AND its ID differs from the owner being edited, reject with a global error.
- [x] 2.5 **Update `createOrUpdateOwnerForm.html`** — add a Thymeleaf block to display global form errors (not field-specific) as a Bootstrap alert above the form fields.
- [x] 2.6 **Inner loop — run tests, verify all pass** — run `./mvnw test` and confirm all new and existing tests pass.
- [x] 2.7 **Write Playwright E2E test** `owner-duplicate-detection.spec.ts` — create an owner, attempt to create the same owner again, verify error message appears, verify no second record was created (search should still return one result).
- [x] 2.8 **Capture proof artifacts** — save test output and screenshot of duplicate error to `docs/specs/03-spec-owner-search-and-data-export/03-proofs/`.

### [x] 3.0 CSV Export of Owner Search Results

Add a `GET /owners.csv` endpoint that exports all matching owners (unpaginated) as a CSV file with proper headers, escaping, and content type. Add an "Export CSV" button on the search results page that passes current search parameters to the CSV endpoint.

#### 3.0 Proof Artifact(s)

- JUnit: `OwnerControllerTests` — MockMvc tests verifying CSV content type and disposition header, header row, data rows with correct values, proper escaping of commas/quotes, empty result set (header only), and search parameter filtering
- Playwright: E2E test that searches for owners, clicks the Export CSV button, and verifies the download contains expected content
- CLI: `curl` command demonstrating CSV download with search parameters

#### 3.0 Tasks

- [x] 3.1 **Outer loop — write failing acceptance tests** in `OwnerControllerTests`: (a) `GET /owners.csv` returns `text/csv` content type and `Content-Disposition` header, (b) response includes header row `First Name,Last Name,Address,City,Telephone`, (c) response includes data rows matching search params, (d) values containing commas/quotes are properly escaped, (e) empty result returns header row only, (f) search params (`lastName`, `telephone`, `city`) filter the exported data.
- [x] 3.2 **Implement CSV export handler** in `OwnerController` — add `@GetMapping("/owners.csv")` method that accepts the same search params, calls the repository for ALL matching owners (no pagination), generates CSV string with proper escaping (RFC 4180), sets response headers, and writes the CSV body.
- [x] 3.3 **Add "Export CSV" button to `ownersList.html`** — add a button/link near the top of the results table that constructs a URL to `/owners.csv` with the current search params (`lastName`, `telephone`, `city`) from the model.
- [x] 3.4 **Inner loop — run tests, verify all pass** — run `./mvnw test` and confirm all new and existing tests pass.
- [x] 3.5 **Write Playwright E2E test** `owner-csv-export.spec.ts` — search for owners, click Export CSV, verify the downloaded file has correct content type and expected rows. Update `owner-page.ts` with `clickExportCsv()` method.
- [x] 3.6 **Capture proof artifacts** — save `curl` output demonstrating CSV download, save to `docs/specs/03-spec-owner-search-and-data-export/03-proofs/`.
