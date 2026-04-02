# 05-spec-visit-management

## Introduction/Overview

The visit scheduling flow currently accepts any date, including dates in the past, which leads to invalid data. Additionally, there is no way to view upcoming visits across all pets and owners. This spec adds past-date validation to the visit form and introduces a new read-only Upcoming Visits page that shows visits scheduled within the next N days.

## Goals

- Prevent scheduling visits with past dates via standard Bean Validation
- Provide a clear, user-friendly error message when a past date is submitted
- Add a new Upcoming Visits page accessible from the main navigation
- Support a configurable `days` query parameter (default 7) for the upcoming visits window
- Display owner, pet, date, and description for each upcoming visit

## User Stories

- **As a receptionist**, I want the system to reject visit dates in the past so that I don't accidentally create invalid visit records.
- **As a clinic manager**, I want to see all upcoming visits for the next week so that I can plan staffing and resources.
- **As a clinic manager**, I want to adjust the time window (e.g., next 14 days, next 30 days) so that I can plan further ahead when needed.

## Demoable Units of Work

### Unit 1: Disallow Scheduling Visits in the Past (Issue #6)

**Purpose:** Add validation to the visit form that rejects dates earlier than today, keeping visit data clean and accurate.

**Functional Requirements:**

- The system shall add a `@FutureOrPresent` annotation to the `date` field in `Visit.java` to reject past dates
- The system shall display a clear validation error message when a past date is submitted (e.g., "must be a date in the present or in the future")
- The system shall accept visit dates for today and any future date
- The system shall continue to accept visits with valid descriptions (existing `@NotBlank` behavior unchanged)
- The system shall use the JVM default clock for determining "today" (no timezone configuration needed)
- The system shall display the validation error inline on the form, consistent with existing error display patterns

**Proof Artifacts:**

- JUnit: `VisitControllerTests` — MockMvc tests for past date rejection, today acceptance, future date acceptance
- Playwright: E2E test that attempts a past date and verifies the validation error message appears

### Unit 2: Upcoming Visits Page (Issue #8)

**Purpose:** Provide a read-only page at `/visits/upcoming` that displays visits scheduled within a configurable number of days, helping clinic staff plan ahead.

**Functional Requirements:**

- The system shall create a new `VisitRepository` interface with a method to find visits between two dates, returning `Page<Visit>` with pagination support
- The system shall create a new controller (or add to an existing one) handling `GET /visits/upcoming`
- The system shall accept an optional `days` query parameter (default 7) specifying the number of days to look ahead from today
- The system shall display each visit's date, description, pet name, and owner name in a table
- The system shall sort visits by date ascending (soonest first)
- The system shall paginate results with 5 items per page, preserving the `days` parameter across pagination links
- The system shall display a friendly "No upcoming visits scheduled" message when no visits exist in the date range
- The system shall add an "Upcoming Visits" nav item to the global header, placed between "Find Owners" and "Veterinarians"
- The system shall validate the `days` parameter (must be a positive integer; invalid values fall back to default 7)
- The Visit entity shall have a `@ManyToOne` relationship back to Pet to enable the query (currently unidirectional from Pet to Visit)

**Proof Artifacts:**

- JUnit: Controller tests for default 7-day window, custom days parameter, empty result set, pagination with days preserved, and invalid days fallback
- Playwright: E2E test that creates a visit for today, navigates to Upcoming Visits, and verifies the visit appears with correct owner/pet/date/description

## Non-Goals (Out of Scope)

1. **Editing visits from the Upcoming Visits page**: The page is read-only; users must go through the owner/pet flow to manage visits
2. **Filtering by vet, owner, or pet**: The upcoming visits page shows all visits, no filtering
3. **Past visits page**: Only future/upcoming visits are shown; no historical view
4. **Visit cancellation or deletion**: Not part of this spec
5. **Time-of-day scheduling**: Visits are date-only, no time component

## Design Considerations

- The Upcoming Visits table should follow the same styling as the Owners and Vets tables (`.table.table-striped.liatrio-table`)
- Columns: Date, Pet, Owner, Description
- The nav item should use a calendar icon (`fa fa-calendar`) and be placed between Find Owners and Veterinarians
- Empty state should be a centered, friendly message — not an empty table
- Use the **frontend-design** and **web-design-guidelines** skills for UI implementation and review

## Repository Standards

- **Architecture**: Follows layered pattern — controller → repository → JPA entity
- **Data Access**: New `VisitRepository` follows Spring Data conventions; uses `@Query` for date range queries joining through Pet to Owner
- **Validation**: Uses Jakarta Bean Validation annotations (`@FutureOrPresent`, `@NotBlank`) with `@Valid` in controller
- **Testing**: `@WebMvcTest` with `@MockitoBean`; Arrange-Act-Assert; Playwright E2E in `e2e-tests/`
- **Pagination**: Spring Data `Pageable` with 5 items per page; pagination links must preserve query params (Definition of Done)
- **Commits**: Conventional commits format `type(scope): description`
- **TDD**: Dual-loop TDD per project constitution
- **i18n**: Any new user-facing text must use message property keys

## Technical Considerations

- **Visit ↔ Pet relationship**: Currently `Pet` has `@OneToMany` to `Visit` but `Visit` has no back-reference to `Pet`. For the upcoming visits query to join Visit → Pet → Owner, we need to add a `@ManyToOne` `pet` field on `Visit`. This is a schema change but should be backward compatible since the `pet_id` foreign key column already exists in the visits table.
- **VisitRepository**: New repository extending `Repository<Visit, Integer>` (following the existing pattern) with a `@Query` that finds visits by date range, joining through Pet to Owner, sorted by date ascending.
- **Query design**: The JPQL query needs to join `Visit` → `Pet` → `Owner` to get all three pieces of data. Since Visit will now have a `@ManyToOne Pet pet` field, the query can navigate `v.pet.owner`.
- **Controller location**: Create a new `VisitController` at the `system` or top-level package, since this page is cross-cutting (not scoped to a single owner/pet). Alternatively, place it in the `owner` package since Visit is already there.
- **Nav item**: Add to the `layout.html` fragment using the existing `menuItem` pattern.

## Security Considerations

No specific security considerations identified. The upcoming visits page is read-only and displays the same data already accessible through the owner detail pages.

## Success Metrics

1. **Validation accuracy**: Past dates are rejected 100% of the time; today and future dates are accepted
2. **Page correctness**: Upcoming visits page shows exactly the visits within the specified date range
3. **Navigation**: Upcoming Visits nav item is visible and functional on all pages
4. **Pagination integrity**: `days` parameter persists across page navigation
5. **Test coverage**: >90% line coverage for all new/modified code with both JUnit and Playwright tests

## Open Questions

No open questions at this time. All requirements have been clarified through the Q&A round.
