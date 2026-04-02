# Proof: Task 2.0 — Upcoming Visits Page

## Test Results

### JUnit — UpcomingVisitsControllerTests

```text
Tests run: 6, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

6 acceptance tests pass:

- `testUpcomingVisitsDefaultDays` — default 7-day window, model has listVisits and days=7
- `testUpcomingVisitsCustomDays` — days=14 param accepted, model has days=14
- `testUpcomingVisitsEmptyResult` — empty result renders view with empty list
- `testUpcomingVisitsPaginationContainsDays` — model has days, currentPage, totalPages for pagination
- `testUpcomingVisitsInvalidDaysFallback` — days=-1 falls back to 7
- `testUpcomingVisitsNonNumericDaysFallback` — days=abc falls back to 7

### Full Test Suite

```text
Tests run: 94, Failures: 0, Errors: 0, Skipped: 5
BUILD SUCCESS
```

## Implementation Summary

### Files Modified

- `Visit.java` — Added `@ManyToOne Pet` with `@JoinColumn(name = "pet_id", insertable = false, updatable = false)` and getter/setter
- `Pet.java` — Added `@ManyToOne Owner` with `@JoinColumn(name = "owner_id", insertable = false, updatable = false)` and getter for JPQL navigation
- `layout.html` — Added "Upcoming Visits" nav item between Find Owners and Veterinarians with calendar icon
- `messages*.properties` (all 9 files) — Added `upcomingVisits`, `noUpcomingVisits`, `pet` i18n keys

### Files Created

- `VisitRepository.java` — Read-only repository with `findUpcomingVisits()` JPQL query joining Visit→Pet→Owner
- `UpcomingVisitsController.java` — Controller for `GET /visits/upcoming` with days param validation and pagination
- `visits/upcomingVisits.html` — Template with Date/Pet/Owner/Description table, empty state message, pagination with days preserved
- `UpcomingVisitsControllerTests.java` — 6 JUnit acceptance tests
- `e2e-tests/tests/pages/upcoming-visits-page.ts` — Playwright page object
- `e2e-tests/tests/features/upcoming-visits.spec.ts` — 4 Playwright E2E tests

## Verification

- Default 7-day window: shows visits for next week
- Custom days param: adjustable window (14, 30, etc.)
- Invalid days: graceful fallback to 7
- Empty state: friendly "No upcoming visits scheduled" message
- Nav item: visible between Find Owners and Veterinarians with calendar icon
- Pagination: preserves days param across pages
- Visit data: shows date, pet name, owner name, description
