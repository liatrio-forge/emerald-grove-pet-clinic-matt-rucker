# Proof: Task 2.0 — Friendly 404 for Missing Owner/Pet

## Test Results

### Full Test Suite

```text
Tests run: 97, Failures: 0, Errors: 0, Skipped: 5
BUILD SUCCESS
```

CrashController integration tests: 2/2 pass (500 error handling unaffected).

## Implementation Summary

### Files Created

- `GlobalExceptionHandler.java` — `@ControllerAdvice` catching `IllegalArgumentException` with `@ResponseStatus(HttpStatus.NOT_FOUND)`, returns "error" view

### Files Modified

- `error.html` — Added "Back to Find Owners" button link in the 404 block, hid raw exception message for 404 status
- `messages*.properties` (all 9 files) — Added `backToFindOwners` i18n key

### Files Created (E2E)

- `e2e-tests/tests/features/friendly-404.spec.ts` — 4 Playwright E2E tests (owner 404, pet 404, no stack traces, 500 still works)

## Verification

- `/owners/99999` returns HTTP 404 with "The requested page was not found" message
- `/owners/1/pets/99999/edit` returns HTTP 404
- No stack traces or internal exception details visible
- "Back to Find Owners" link navigates to /owners/find
- `/oups` still returns HTTP 500 (not affected by the handler)
- CrashController integration tests still pass
