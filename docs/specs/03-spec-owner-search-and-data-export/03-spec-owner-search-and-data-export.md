# 03-spec-owner-search-and-data-export

## Introduction/Overview

The Find Owners flow currently only supports searching by last name. This spec extends the search with optional telephone and city filters, adds duplicate detection during owner creation and update, and provides a CSV export of search results. All three capabilities center on `OwnerController`, `OwnerRepository`, and the Find Owners templates, making them a natural cohesive unit of work.

## Goals

- Allow users to find owners by any combination of last name, telephone, and city
- Prevent creation of duplicate owner records using a clear, enforceable rule
- Enable CSV download of owner search results for offline use
- Preserve all search/filter parameters across pagination links (fix existing gap)
- Maintain backward compatibility with the current last-name-only search behavior

## User Stories

- **As a receptionist**, I want to search for owners by telephone number so that I can quickly pull up their record when they call the clinic.
- **As a receptionist**, I want to search for owners by city so that I can find all owners in a specific area.
- **As a clinic administrator**, I want to be prevented from creating a duplicate owner record so that the database stays clean and accurate.
- **As a clinic administrator**, I want to export a list of owners matching my search criteria as a CSV file so that I can use the data in spreadsheets or reports.

## Demoable Units of Work

### Unit 1: Extended Owner Search (Issue #3)

**Purpose:** Allow the Find Owners form to filter by telephone and city in addition to last name, with all parameters preserved across pagination.

**Functional Requirements:**

- The system shall add optional `telephone` and `city` input fields to the Find Owners form (`findOwners.html`)
- The system shall accept `lastName`, `telephone`, and `city` as optional query parameters on `GET /owners`
- The system shall combine provided parameters with AND logic — only owners matching all non-empty fields are returned
- The system shall match `lastName` using case-insensitive starts-with (existing behavior)
- The system shall match `city` using case-insensitive starts-with
- The system shall match `telephone` using starts-with (digits only)
- The system shall validate the `telephone` search field as exactly 10 digits when provided (same rule as the creation form)
- The system shall display a validation error on the Find Owners form if the telephone field contains non-digit characters or is not exactly 10 digits
- The system shall ignore empty/blank filter fields (treat as "match all" for that dimension)
- The system shall preserve all search parameters (`lastName`, `telephone`, `city`) in pagination links
- The system shall pre-fill the search form fields with the current filter values when returning results
- The system shall continue to redirect directly to owner details when exactly one result is found

**Proof Artifacts:**

- JUnit: `OwnerControllerTests` — MockMvc tests for multi-field search, single-result redirect, no-results error, and telephone validation error
- Playwright: E2E test that creates an owner, searches by telephone, verifies the owner appears, pages forward/back and verifies filters persist in the URL

### Unit 2: Duplicate Owner Detection (Issue #4)

**Purpose:** Prevent creating or updating an owner to match an existing record, using a clear duplicate rule based on firstName + lastName + telephone (case-insensitive).

**Functional Requirements:**

- The system shall check for duplicate owners during creation (`POST /owners/new`)
- The system shall check for duplicate owners during update (`POST /owners/{ownerId}/edit`), excluding the owner being edited from the duplicate check
- The system shall define a duplicate as an existing owner with the same `firstName`, `lastName`, and `telephone` (case-insensitive comparison)
- The system shall reject the form submission and display a clear, user-friendly error message when a duplicate is detected (e.g., "An owner with this name and telephone number already exists")
- The system shall not create or update the owner record when a duplicate is detected
- The system shall add a repository method to check for existing owners by firstName + lastName + telephone (case-insensitive)
- The system shall display the duplicate error as a global form error (not tied to a single field) since it spans multiple fields

**Proof Artifacts:**

- JUnit: `OwnerControllerTests` — MockMvc tests for duplicate detection on create, duplicate detection on update (excluding self), and successful save when no duplicate exists
- Playwright: E2E test that creates an owner, attempts to create the same owner again, and verifies the error message appears without creating a second record

### Unit 3: CSV Export of Search Results (Issue #9)

**Purpose:** Provide a CSV download endpoint for owner search results, with a UI button on the search results page.

**Functional Requirements:**

- The system shall expose a `GET /owners.csv` endpoint that accepts the same search parameters as `GET /owners` (`lastName`, `telephone`, `city`)
- The system shall return a response with `Content-Type: text/csv` and a `Content-Disposition: attachment; filename="owners.csv"` header
- The system shall include a header row: `First Name,Last Name,Address,City,Telephone`
- The system shall export ALL matching owners regardless of pagination (not limited to one page)
- The system shall properly escape CSV values containing commas, quotes, or newlines
- The system shall return an empty CSV (header row only) when no owners match the search criteria
- The system shall add an "Export CSV" button/link on the `ownersList.html` results page that includes the current search parameters in the link URL
- The system shall not display the "Export CSV" button on the Find Owners form (only on the results page)

**Proof Artifacts:**

- JUnit: `OwnerControllerTests` — MockMvc tests verifying CSV content type, header row, data rows, proper escaping, empty result set, and search parameter filtering
- Playwright: E2E test that searches for owners, clicks the Export CSV button, and verifies the downloaded file contains expected data

## Non-Goals (Out of Scope)

1. **Advanced search operators**: No OR logic, negation, wildcards, or full-text search beyond starts-with matching
2. **Search by pet name or vet**: Only owner-level fields (lastName, telephone, city) are searchable
3. **CSV import**: This spec only covers export; importing owner data from CSV is out of scope
4. **Real-time duplicate checking**: No AJAX/JavaScript-based duplicate detection as the user types; validation occurs only on form submission
5. **Configurable CSV columns**: The column set is fixed (firstName, lastName, address, city, telephone)
6. **Search result sorting**: Results use the default repository ordering; no user-selectable sort is added

## Design Considerations

- The Find Owners form should add `telephone` and `city` fields below the existing `lastName` field, maintaining the current form layout style
- The "Export CSV" button should be placed near the top of the results list, styled consistently with existing action buttons
- Error messages for duplicate detection should be displayed as a global form alert (Bootstrap-style alert box above the form), not inline on a single field
- Use the **frontend-design** and **web-design-guidelines** skills for UI implementation and review

## Repository Standards

- **Architecture**: Follows layered pattern — controller → repository → JPA entity
- **Search**: Current pattern uses Spring Data derived query methods (`findByLastNameStartingWith`); extending to multi-field search will likely require a custom `@Query` or `Specification`-based approach
- **Validation**: Uses Bean Validation annotations (`@NotBlank`, `@Pattern`) with `BindingResult`; duplicate detection adds programmatic validation in the controller
- **Testing**: `@WebMvcTest` with `@MockitoBean` for controller tests; Arrange-Act-Assert pattern; Playwright E2E tests in `e2e-tests/`
- **Pagination**: Uses Spring Data `Pageable` with 5 items per page; current implementation does not preserve query params — this spec fixes that
- **Commits**: Conventional commits format `type(scope): description`
- **TDD**: Dual-loop TDD required per project constitution

## Technical Considerations

- **Multi-field search query**: The current `findByLastNameStartingWith` method only supports one field. The new search will need a custom query (JPQL `@Query` or Spring Data `Specification`) to handle optional AND-combined filters
- **Pagination URL fix**: The `ownersList.html` template pagination links must include all active search params as query parameters (currently they only link to `/owners?page=N`)
- **CSV generation**: Use standard Java I/O (`StringBuilder` or `PrintWriter`) to generate CSV content directly in the controller or a helper class. No external CSV library needed for this simple case, per the Library-First principle — verify no existing dependency covers this first
- **Content negotiation**: The `/owners.csv` endpoint should be a separate handler method (not content negotiation on `/owners`) to keep the HTML and CSV flows independent
- **Duplicate check query**: Add a repository method like `findByFirstNameIgnoreCaseAndLastNameIgnoreCaseAndTelephoneIgnoreCase` or a custom `@Query`

## Security Considerations

- CSV export should not include any sensitive data beyond what is already displayed on the search results page (firstName, lastName, address, city, telephone)
- The duplicate detection query should use parameterized queries (Spring Data handles this) to prevent SQL injection
- CSV export is not authenticated beyond the application's existing security model (currently no auth)

## Success Metrics

1. **Search coverage**: Users can find owners using any combination of lastName, telephone, and city with zero false negatives for starts-with matches
2. **Zero duplicate owners**: Duplicate detection blocks 100% of attempts to create owners matching the firstName + lastName + telephone rule
3. **Pagination integrity**: All search parameters persist across every page navigation — no parameter loss
4. **CSV accuracy**: Exported CSV contains all matching owners with properly escaped values, matching the search results displayed in the UI
5. **Test coverage**: >90% line coverage for all new/modified code with both JUnit and Playwright tests

## Open Questions

No open questions at this time. All requirements have been clarified through the Q&A round.
