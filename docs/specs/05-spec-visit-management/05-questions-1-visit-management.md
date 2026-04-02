# 05 Questions Round 1 - Visit Management

Please answer each question below (select one or more options, or add your own notes). Feel free to add additional context under any question.

## 1. Past Date Validation Approach

How should the past-date validation be implemented?

- [x] (B) Annotation-based — add `@FutureOrPresent` on the date field in Visit.java

## 2. "Today" Boundary

The issue says "date must be today or later." Should we use server time or is there any timezone concern?

- [x] JVM default (server local time) — `@FutureOrPresent` uses JVM default clock natively

## 3. Upcoming Visits Page — Navigation

How should users access the upcoming visits page?

- [x] (A) Add a new nav item in the header (e.g., "Upcoming Visits")

## 4. Upcoming Visits Page — Empty State

What should the page show when there are no upcoming visits?

- [x] (A) A friendly "No upcoming visits" message

## 5. Upcoming Visits — Data Access

Since no VisitRepository exists (visits are saved via Owner cascade), how should we query upcoming visits?

- [x] (A) Create a new VisitRepository with a date-range query (cleanest for this use case)

## 6. Upcoming Visits — Sorting

How should the visits be sorted?

- [x] (A) By date ascending (soonest first)

## 7. Upcoming Visits — Pagination

Should the upcoming visits page be paginated?

- [x] (A) Yes — same 5-per-page pattern as other lists

## 8. Proof Artifacts

What proof artifacts would you like?

- [x] (A) Playwright E2E tests + JUnit controller tests (comprehensive)
