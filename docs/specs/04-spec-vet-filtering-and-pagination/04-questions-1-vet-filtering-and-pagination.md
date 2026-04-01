# 04 Questions Round 1 - Vet Filtering and Pagination

Please answer each question below (select one or more options, or add your own notes). Feel free to add additional context under any question.

## 1. Specialty Filter UI Control

What type of filter control should be used for selecting a specialty?

- [x] (C) Clickable tag/pill buttons for each specialty (modern, visual)

## 2. "All" and "None" Handling

How should the filter handle "All vets" and vets with no specialty?

- [x] (A) Default shows all vets; an explicit "None" option filters to vets with no specialty

## 3. Filter Activation Method

How should the filter be applied?

- [x] (A) Immediately on selection change (no submit button needed)

## 4. URL Query Parameter

The issue mentions query param support for shareable URLs. What param name?

- [x] (C) `filter` (e.g., `/vets.html?filter=radiology`)

## 5. REST Endpoint Filtering

Should the JSON REST endpoint (`GET /vets`) also support specialty filtering?

- [x] (A) Yes — same query param support as the HTML endpoint

## 6. Caching Consideration

The current vet queries use `@Cacheable("vets")`. Adding filtering means different results for different params. How should we handle this?

- [x] (A) Remove caching for the filtered query (simplest, small dataset)

## 7. Proof Artifacts

What proof artifacts would you like for this spec?

- [x] (A) Playwright E2E tests + JUnit controller tests (comprehensive)
