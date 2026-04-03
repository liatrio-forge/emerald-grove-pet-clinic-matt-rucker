# 08-spec-ui-fixes

## Introduction/Overview

Two UI issues need fixing: the "Error" nav item visible to users that links to a developer debug endpoint, and the vet specialty filter pills that use Bootstrap default styles clashing with the Liatrio dark theme. The active pill gets a `margin-top: 12px` from `.btn-primary` causing misalignment.

## Goals

- Remove the Error nav item from the header
- Restyle vet filter pills to match the Liatrio dark theme
- Fix active pill alignment issue caused by `.btn-primary` margin-top override

## User Stories

- **As a user**, I don't want to see a developer "Error" link in the navigation.
- **As a user**, I want the vet specialty filters to look polished and consistent with the rest of the dark-themed site.

## Demoable Units of Work

### Unit 1: Remove Error Nav Item and Fix Filter Pills

**Purpose:** Clean up the nav bar and restyle the vet filter pills to use Liatrio theme colors and consistent sizing.

**Functional Requirements:**

- The system shall remove the "Error" menu item from the global header nav in `layout.html`
- The system shall restyle vet filter pills to use Liatrio theme colors: `#333333` border with `#f8f9fa` text for inactive, `#24AE1D` background with `#111111` text for active
- The system shall ensure the active pill does not shift position (fix `margin-top` from `.btn-primary` override)
- The system shall add custom CSS classes for the filter pills instead of relying on Bootstrap's `btn-primary`/`btn-outline-primary`
- The system shall maintain all existing filter functionality
- The system shall ensure pills wrap gracefully on smaller screens

**Proof Artifacts:**

- JUnit: Existing tests pass (no regressions)
- Playwright: E2E test verifying Error nav item is gone and filter pills render correctly

## Non-Goals

1. Redesigning other parts of the site
2. Changing the CrashController or `/oups` endpoint (only removing the nav link)

## Repository Standards

Follow existing Liatrio CSS patterns, conventional commits, TDD.

## Technical Considerations

- The `.btn-primary` CSS override adds `margin-top: 12px` which causes the alignment issue. The filter pills should use custom classes (e.g., `liatrio-filter-pill`, `liatrio-filter-pill--active`) instead of Bootstrap button classes.
- Add the new CSS to `petclinic.css`.

## Open Questions

None.
