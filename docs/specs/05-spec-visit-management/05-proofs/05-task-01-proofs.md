# Proof: Task 1.0 — Disallow Scheduling Visits in the Past

## Test Results

### JUnit — VisitControllerTests

```text
Tests run: 6, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

3 new acceptance tests pass:

- `testProcessNewVisitFormRejectsPastDate` — past date rejected with field error on `date`
- `testProcessNewVisitFormAcceptsTodayDate` — today's date accepted, redirects to owner details
- `testProcessNewVisitFormAcceptsFutureDate` — future date accepted, redirects to owner details

All 3 existing tests continue to pass (no regressions).

### Full Test Suite

```text
Tests run: 88, Failures: 0, Errors: 0, Skipped: 5
BUILD SUCCESS
```

## Implementation Summary

### Files Modified

- `Visit.java` — Added `@FutureOrPresent` annotation on `date` field with `jakarta.validation.constraints.FutureOrPresent` import

### Files Created

- `e2e-tests/tests/features/visit-date-validation.spec.ts` — 2 Playwright E2E tests (past date rejection, today acceptance)

## Verification

- Past date: rejected with "must be a date in the present or in the future" error
- Today: accepted, redirects with "Your visit has been booked" message
- Future date: accepted, redirects successfully
- Existing description validation: still works (`@NotBlank` unchanged)
