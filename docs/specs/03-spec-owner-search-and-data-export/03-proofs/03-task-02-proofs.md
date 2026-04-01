# Proof: Task 2.0 — Duplicate Owner Detection on Create and Update

## Test Results

### JUnit — OwnerControllerTests

```text
Tests run: 25, Failures: 0, Errors: 0, Skipped: 0
BUILD SUCCESS
```

All 4 new duplicate detection tests pass:

- `testProcessCreationFormDuplicateRejected` — create with matching firstName+lastName+telephone is rejected with global error
- `testProcessCreationFormNoDuplicateSucceeds` — create with no match redirects successfully
- `testProcessUpdateOwnerFormDuplicateRejected` — update to match another owner (different ID) is rejected
- `testProcessUpdateOwnerFormSelfExclusionSucceeds` — update with unchanged fields succeeds (self-exclusion works)

### Full Test Suite

```text
Tests run: 71, Failures: 0, Errors: 0, Skipped: 5
BUILD SUCCESS
```

## Implementation Summary

### Files Modified

- `OwnerRepository.java` — Added `findByFirstNameIgnoreCaseAndLastNameIgnoreCaseAndTelephoneIgnoreCase()` derived query method returning `List<Owner>`
- `OwnerController.java` — Added `isDuplicate()` helper method with self-exclusion logic, called from both `processCreationForm()` (excludeId=null) and `processUpdateOwnerForm()` (excludeId=ownerId)
- `createOrUpdateOwnerForm.html` — Added global error display block with Bootstrap `alert-danger` class above form fields

### Files Created

- `e2e-tests/tests/features/owner-duplicate-detection.spec.ts` — Playwright E2E test: creates owner, attempts duplicate, verifies error, confirms single record

## Verification

- Create duplicate: blocked with "An owner with this name and telephone number already exists."
- Create with different telephone: succeeds
- Update to match another owner: blocked
- Update with same fields (self): succeeds (self-exclusion)
- Global error displays as Bootstrap alert above form
