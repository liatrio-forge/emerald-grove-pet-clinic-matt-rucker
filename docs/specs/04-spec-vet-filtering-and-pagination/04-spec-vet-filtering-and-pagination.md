# 04-spec-vet-filtering-and-pagination

## Introduction/Overview

The Vet Directory currently displays all veterinarians in a paginated list with no filtering capability. This spec adds a specialty filter using clickable tag/pill buttons so users can narrow the vet list by specialty, and fixes the pagination links to preserve the active filter across page navigation. Both the HTML view and JSON REST endpoint will support the filter parameter.

## Goals

- Allow users to filter the Vet Directory by specialty using clickable pill buttons
- Provide an "All" default and a "None" option to find vets with no specialty
- Support shareable filtered URLs via a `filter` query parameter
- Preserve the active filter across pagination links
- Extend the JSON REST endpoint (`GET /vets`) with the same filter support

## User Stories

- **As a pet owner**, I want to filter veterinarians by specialty so that I can find a vet with the expertise my pet needs.
- **As a pet owner**, I want to share a filtered vet list URL with others so that they can see the same results without re-filtering.
- **As a clinic receptionist**, I want to see which vets have no specialty so that I can identify general practice vets.
- **As a developer**, I want the REST endpoint to support the same filter so that API consumers get consistent behavior.

## Demoable Units of Work

### Unit 1: Specialty Filter on Vet Directory (Issue #2)

**Purpose:** Add clickable tag/pill buttons for each specialty (plus "All" and "None") to the Vet Directory page, with immediate filtering on click and query param support for shareable URLs.

**Functional Requirements:**

- The system shall display clickable tag/pill buttons above the vet table for each specialty in the database, plus "All" and "None" options
- The system shall highlight/activate the currently selected filter button
- The system shall filter the vet list immediately when a pill button is clicked (no submit button)
- The system shall use the `filter` query parameter (e.g., `/vets.html?filter=radiology`) to specify the active specialty filter
- The system shall treat an empty or absent `filter` parameter as "All" (show all vets)
- The system shall treat `filter=none` as a request to show only vets with no specialty
- The system shall match the `filter` value against specialty names (case-insensitive)
- The system shall display the full vet list when an unrecognized `filter` value is provided (graceful fallback to "All")
- The system shall add a repository method to find vets by specialty name with pagination
- The system shall add a repository method to find vets with no specialties with pagination
- The system shall not cache the filtered query results (remove `@Cacheable` for the new filtered methods)
- The system shall populate the available specialty list from the database (not hardcoded)
- The `GET /vets` JSON endpoint shall also accept the `filter` query parameter and return filtered results

**Proof Artifacts:**

- JUnit: `VetControllerTests` — MockMvc tests for filter by specialty, filter by "none", no filter (all vets), unrecognized filter fallback, and JSON endpoint with filter
- Playwright: E2E test that opens the Vet Directory, clicks a specialty pill, verifies filtered results, and verifies the URL contains the filter param
- Screenshot: Vet Directory with specialty pill buttons visible

### Unit 2: Preserve Filter Across Vet Pagination (Issue #5)

**Purpose:** Ensure pagination links on the Vet Directory include the active `filter` parameter so the filter persists when navigating pages.

**Functional Requirements:**

- The system shall include the `filter` query parameter in all pagination links (page numbers, first, previous, next, last) when a filter is active
- The system shall not include the `filter` parameter in pagination links when no filter is active (clean URLs)
- The system shall pass the current filter value to the template model for use in pagination link construction
- The system shall maintain the highlighted/active pill button state after pagination

**Proof Artifacts:**

- JUnit: `VetControllerTests` — MockMvc test verifying the model contains the filter value for pagination
- Playwright: E2E test that applies a filter, navigates to page 2, and verifies the filter param persists in the URL and the correct pill remains highlighted

## Non-Goals (Out of Scope)

1. **Multi-specialty filtering**: Users cannot select multiple specialties simultaneously — only one filter at a time
2. **Vet name search**: No text search for vet names; only specialty filtering
3. **Sorting**: No user-selectable sort order for the vet list
4. **Owner list pagination for this spec**: Already fixed in Spec 03
5. **Cache optimization**: Not adding per-filter caching — simply removing cache for filtered queries

## Design Considerations

- Specialty pill buttons should be styled consistently with the existing Liatrio theme (use existing CSS classes or Bootstrap pill/badge styles)
- The active pill should have a visually distinct style (e.g., filled vs outlined, or different background color)
- Pills should be placed above the vet table in a horizontal row that wraps on smaller screens
- "All" pill should appear first, followed by specialty pills in alphabetical order, with "None" last
- Use the **frontend-design** and **web-design-guidelines** skills for UI implementation and review

## Repository Standards

- **Architecture**: Follows layered pattern — controller → repository → JPA entity
- **Filtering**: New queries will use custom `@Query` (JPQL) to filter by specialty name or no-specialty
- **Validation**: Graceful fallback for unrecognized filter values (no error, just show all)
- **Testing**: `@WebMvcTest` with `@MockitoBean` for controller tests; Arrange-Act-Assert; Playwright E2E in `e2e-tests/`
- **Pagination**: Uses Spring Data `Pageable` with 5 items per page; pagination links must include filter params (Definition of Done)
- **Commits**: Conventional commits format `type(scope): description`
- **TDD**: Dual-loop TDD required per project constitution
- **i18n**: Any new user-facing text must use message property keys

## Technical Considerations

- **Specialty list population**: The controller needs to query all distinct specialties from the database and pass them to the template model. A `SpecialtyRepository` or a method on `VetRepository` may be needed
- **Filtered vet query**: Need a JPQL `@Query` that joins `Vet` → `Specialty` and filters by specialty name, returning `Page<Vet>`. For "none", query vets where the specialties collection is empty
- **Caching**: The new filtered queries should NOT use `@Cacheable`. The existing `findAll()` methods can retain their cache
- **Pill button implementation**: Each pill is an anchor tag (`<a>`) linking to `/vets.html?filter=<specialty-name>`, so clicking triggers a full page load with the filter applied. No JavaScript required for immediate filtering
- **REST endpoint**: The existing `showResourcesVetList()` method returns a `Vets` wrapper. The filtered version should accept an optional `filter` param and return only matching vets

## Security Considerations

No specific security considerations identified. The filter parameter is a simple string matched against specialty names — no injection risk with Spring Data parameterized queries.

## Success Metrics

1. **Filter accuracy**: Selecting a specialty shows only vets with that specialty; "None" shows only vets with no specialty
2. **Pagination integrity**: Filter parameter persists across all page navigation links — no parameter loss
3. **URL shareability**: Copying a filtered URL and pasting it in a new tab produces the same filtered results
4. **REST parity**: JSON endpoint returns the same filtered results as the HTML view for the same `filter` param
5. **Test coverage**: >90% line coverage for all new/modified code with both JUnit and Playwright tests

## Open Questions

No open questions at this time. All requirements have been clarified through the Q&A round.
