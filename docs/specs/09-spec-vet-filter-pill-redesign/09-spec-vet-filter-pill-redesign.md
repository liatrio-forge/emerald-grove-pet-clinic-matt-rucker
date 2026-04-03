# 09-spec-vet-filter-pill-redesign

## Introduction/Overview

The vet specialty filter pills on the Veterinarians page are visually broken — they render as flat text with no pill shape, no visible borders, and no clear active state. This spec fixes the CSS to create properly styled rounded pill buttons that match the Liatrio dark theme, with outlined inactive state and green-outlined active state.

## Goals

- Fix filter pills to render as visually distinct rounded pill shapes with visible borders
- Create a clear active state using green outline and green text
- Contain the pills in a dark bordered bar that visually separates the filter section
- Ensure no alignment shifting between active and inactive states
- Match the Liatrio dark theme color palette

## User Stories

- **As a user**, I want the specialty filter options to look like clickable buttons so that I know they are interactive.
- **As a user**, I want to clearly see which filter is currently selected so that I know what I'm viewing.

## Demoable Units of Work

### Unit 1: Redesign Filter Pill CSS and Template

**Purpose:** Replace the broken CSS with properly styled rounded pill buttons in a dark container bar, with outlined inactive state and green-outlined active state.

**Functional Requirements:**

- The system shall render filter pills as fully rounded pill shapes (large border-radius for capsule/pill ends)
- The system shall style inactive pills with a visible `#333333` border, transparent background, and `#b3b3b3` muted text
- The system shall style the active/selected pill with a `#24AE1D` green border and `#24AE1D` green text, transparent background
- The system shall show a hover state on inactive pills (brighter text, subtle border color change)
- The system shall contain the pills in a dark bar (`#1a1f23` background, `#333333` border, `8px` border-radius) that visually separates the filter section from the table
- The system shall maintain consistent pill height and alignment — no shifting when switching between active and inactive states
- The system shall ensure pills wrap gracefully on smaller screens with consistent gap spacing
- The system shall preserve all existing filter functionality (All, specialty names, None — clicking navigates with `?filter=` param)

**Proof Artifacts:**

- Playwright: E2E test verifying filter pills are visible, clickable, and the active pill has the correct CSS class
- Screenshot: Veterinarians page showing the redesigned filter pills with one active

## Non-Goals (Out of Scope)

1. **Changing filter logic**: Only visual CSS changes; no changes to controller, repository, or filter behavior
2. **Redesigning other components**: Only the vet filter pills are in scope
3. **Adding new filters**: The same All/specialties/None options remain

## Design Considerations

- **Pill shape**: Use `border-radius: 9999px` for fully rounded capsule ends
- **Inactive state**: `border: 1px solid #333333`, `background: transparent`, `color: #b3b3b3`
- **Active state**: `border: 1px solid #24AE1D`, `background: transparent`, `color: #24AE1D`, `font-weight: 600`
- **Hover state**: `color: #f8f9fa`, `border-color: #555` (subtle brightening)
- **Container bar**: `background: #1a1f23`, `border: 1px solid #333333`, `border-radius: 8px`, `padding: 12px 16px`
- **Gap between pills**: `8px` (using flexbox gap)
- **Critical fix**: Override any inherited `margin-top` from Bootstrap `.btn-primary` — use `margin-top: 0 !important` if needed, or avoid using `.btn` classes entirely
- Use the **frontend-design** skill for implementation and **web-design-guidelines** skill for review

## Repository Standards

- CSS changes go in `petclinic.css` using the existing Liatrio CSS variable system
- Template changes in `vetList.html`
- Follow conventional commits
- TDD: write Playwright test first, then implement CSS fix
- Run `./mvnw test` to verify no regressions

## Technical Considerations

- **Root cause of current issue**: The existing CSS in `petclinic.css` uses SCSS-compiled syntax with closing braces on the same line (e.g., `border: 1px solid #333; }`). While valid CSS, there may be specificity conflicts with Bootstrap's base anchor (`a`) or button styles that override the custom pill styles. The fix should ensure sufficient specificity.
- **Avoiding Bootstrap conflicts**: Do NOT use any `.btn` classes on the pills. Use only custom `.liatrio-filter-pill` classes to avoid inheriting Bootstrap button overrides (especially `margin-top: 12px` from `.btn-primary`).
- **Browser cache**: After CSS changes, the app must be restarted and the browser cache cleared to see updates. Static resources are cached for 12 hours per `application.properties`.

## Security Considerations

No specific security considerations identified. This is a CSS-only change.

## Success Metrics

1. **Visual correctness**: Pills render as rounded capsule shapes with visible borders on all screen sizes
2. **Active state clarity**: Active pill is clearly distinguishable with green border/text
3. **Alignment stability**: No shifting or layout changes when clicking between pills
4. **Theme consistency**: Pills visually belong to the Liatrio dark theme
5. **No regressions**: All existing tests pass, filter functionality unchanged

## Open Questions

No open questions at this time.
