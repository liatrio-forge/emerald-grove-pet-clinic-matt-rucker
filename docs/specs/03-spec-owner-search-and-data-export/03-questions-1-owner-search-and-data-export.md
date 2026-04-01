# 03 Questions Round 1 - Owner Search and Data Export

Please answer each question below (select one or more options, or add your own notes). Feel free to add additional context under any question.

## 1. Extended Search Behavior

How should the new telephone and city fields combine with the existing lastName search?

- [x] (C) AND logic, but all fields are optional — empty fields are ignored (most flexible)

## 2. City Search Matching

How should the city field match?

- [x] (B) Starts-with match (like lastName currently works)

## 3. Telephone Search Matching

How should the telephone field match? Current telephone format is exactly 10 digits.

- [x] (B) Starts-with match (partial phone number)

## 4. Telephone Search Validation

Should the telephone search field enforce the same 10-digit validation as the creation form, or be more lenient for search?

- [x] (A) Same strict validation — must be exactly 10 digits if provided

## 5. Duplicate Detection Rule

What combination of fields defines a "duplicate" owner?

- [x] (A) Same firstName + lastName + telephone (as suggested in the issue)

## 6. Duplicate Detection Matching Strictness

How strict should duplicate matching be?

- [x] (A) Case-insensitive exact match (e.g., "John Smith" matches "john smith")

## 7. Duplicate Detection Timing

When should duplicate detection occur?

- [x] (B) During creation AND update (also check on edit save)

## 8. CSV Export Columns

What columns should the CSV export include?

- [x] (A) Minimal: firstName, lastName, address, city, telephone (as suggested in issue)

## 9. CSV Export Trigger

How should the user trigger the CSV export?

- [x] (C) Both — UI button that links to the CSV endpoint with current search params

## 10. CSV Export and Pagination

Should the CSV export respect pagination or export ALL matching results?

- [x] (A) Export ALL matching results regardless of pagination (most useful)

## 11. Proof Artifacts

What proof artifacts would you most like to see for each feature?

- [x] (A) Playwright E2E tests + JUnit controller tests (comprehensive)
