# 09 Tasks - Vet Filter Pill Redesign

Spec: [09-spec-vet-filter-pill-redesign.md](09-spec-vet-filter-pill-redesign.md)

## Relevant Files

- `src/main/resources/static/resources/css/petclinic.css` — Fix/replace the broken `.liatrio-filter-pill` CSS
- `src/main/resources/templates/vets/vetList.html` — Verify template uses correct classes (already updated in prior commit)
- `e2e-tests/tests/features/vet-filter-pills-visual.spec.ts` — New Playwright E2E test for pill rendering
- `e2e-tests/tests/features/vet-filter.spec.ts` — Existing filter E2E tests (verify no regression)

### Notes

- No Java code changes — CSS and template only
- The template already uses `liatrio-filter-pill` and `liatrio-filter-pill--active` classes from the prior commit
- The CSS needs to be rewritten to fix specificity issues and ensure pills render correctly
- Run `./mvnw test` to verify no regressions
- Use `frontend-design` skill for implementation, `web-design-guidelines` for review

## Tasks

### [x] 1.0 Redesign Filter Pill CSS and Template

Replace the broken CSS with properly styled rounded pill buttons in a dark container bar.

#### 1.0 Proof Artifact(s)

- Playwright: E2E test verifying pills are visible with correct classes and active state works
- Screenshot: Veterinarians page showing redesigned filter pills

#### 1.0 Tasks

- [x] 1.1 **Outer loop — write failing Playwright E2E test** `vet-filter-pills-visual.spec.ts`: (a) verify filter pills container (`#specialty-filters`) is visible, (b) verify each pill has `liatrio-filter-pill` class, (c) verify active pill has `liatrio-filter-pill--active` class, (d) click a specialty pill and verify it gets the active class, (e) verify pills have visible borders (computed border-style is not 'none').
- [x] 1.2 **Rewrite `.liatrio-filter-pill` CSS in `petclinic.css`** — replace the existing broken CSS block with properly formatted rules: rounded pill shape (`border-radius: 9999px`), outlined inactive state (`#333` border, transparent background, `#b3b3b3` text), green-outlined active state (`#24AE1D` border + text), hover state, dark container bar. Ensure no `.btn` classes are inherited. Use `!important` on `margin-top: 0` if needed to override Bootstrap.
- [x] 1.3 **Verify template markup** — confirm `vetList.html` uses `liatrio-filter-bar` for the container and `liatrio-filter-pill` / `liatrio-filter-pill--active` for pills with no `.btn` classes.
- [x] 1.4 **Inner loop — run tests, verify all pass** — run `./mvnw test` and confirm no regressions. Restart the app and visually verify in browser.
- [x] 1.5 **Review with web-design-guidelines skill** — run the web-design-guidelines skill to audit the redesigned pills for accessibility and design compliance.
- [x] 1.6 **Capture proof artifacts** — Playwright screenshot of the pills, save to `docs/specs/09-spec-vet-filter-pill-redesign/09-proofs/`.
