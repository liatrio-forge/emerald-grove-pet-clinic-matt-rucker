# Emerald Grove Veterinary Clinic — Style Guide

This document defines the visual design system for the application. All UI changes must reference this guide. AI agents must verify compliance before committing visual changes (see Constitution Article 10).

## Color Palette

### Backgrounds

| Token | Hex | Usage |
|---|---|---|
| Background (body) | `#1a1f23` | Page background |
| Background (card) | `#1E2327` | Cards, table rows (even), pagination bar |
| Background (dark) | `#111111` | Hero, navbar, table headers, form inputs |
| Background (stripe) | `#1a1f23` | Table rows (odd), filter bar |

### Accents

| Token | Hex | Usage |
|---|---|---|
| Primary green | `#24AE1D` | Buttons, focus rings, active states, form focus borders |
| Accent lime | `#89df00` | Eyebrow text, table links |
| Danger red | `#dc3545` | Destructive actions (delete buttons) |

### Text

| Token | Hex | Usage |
|---|---|---|
| Primary text | `#f8f9fa` | Headings, body text, labels, table cells |
| Secondary text | `#cccccc` | Subtitles, nav links, pagination text |
| Muted text | `#b3b3b3` | Help text, inactive filter pills |
| Placeholder text | `#666666` | Form input placeholders |

### Borders

| Token | Hex | Usage |
|---|---|---|
| Default border | `#333333` | Cards, tables, form inputs, filter pills, footer |
| Hover border | `#555555` | Filter pill hover |

## Typography

| Element | Font | Size | Weight | Line Height | Notes |
|---|---|---|---|---|---|
| Body / default | DM Sans | Bootstrap default | 400 | Bootstrap default | |
| Headings (h1–h6) | DM Sans | varies | 400 | varies | Color: `#f8f9fa` |
| Hero title | DM Sans | 40px | 400 | 1.1 | |
| Hero subtitle | DM Sans | 18px | 400 | 1.6 | Color: `#cccccc` |
| Eyebrow | DM Sans | 12px | 400 | default | Uppercase, `0.08em` letter-spacing, color: `#89df00` |
| Navbar links | DM Sans | 14px | 400 | default | Uppercase |
| Navbar brand | DM Sans | 16px | 600 | 1.2 | `0.02em` letter-spacing |
| Filter pills | DM Sans | 13px | 500 (600 active) | 1.4 | |

## Spacing Scale

Uses CSS custom properties with a 4px base unit:

| Variable | Value | Usage examples |
|---|---|---|
| `--liatrio-space-1` | 4px | Tight gaps |
| `--liatrio-space-2` | 8px | Icon gaps, pill gaps, pagination gaps |
| `--liatrio-space-3` | 12px | Button gaps, form action gaps, padding |
| `--liatrio-space-4` | 16px | Section padding, margin-bottom |
| `--liatrio-space-6` | 24px | Card padding |
| `--liatrio-space-8` | 32px | Page top/bottom padding, hero padding |
| `--liatrio-space-12` | 48px | Footer margin-top, page bottom padding |

## Border Radius

| Variable | Value | Usage |
|---|---|---|
| `--liatrio-radius-sm` | 4px | Small elements |
| `--liatrio-radius-md` | 8px | Pagination bar, filter bar |
| `--liatrio-radius-lg` | 16px | Cards, hero section |
| Pill shape | 9999px | Filter pills |

## Shadows

| Variable | Value | Usage |
|---|---|---|
| `--liatrio-shadow-sm` | `0 1px 2px rgba(17,17,17,0.08)` | Cards, hero image |
| `--liatrio-shadow-md` | `0 8px 24px rgba(17,17,17,0.12)` | Hero section |

## Components

### Cards

All card types share a common base: `#1E2327` background, `#333` border, `16px` radius, `24px` padding, subtle shadow.

- **`.liatrio-feature-card`** — Homepage feature descriptions
- **`.liatrio-form-card`** — Form containers (max-width: 820px)
- **`.liatrio-table-card`** — Table containers with header
- **`.liatrio-error-card`** — Error page content

### Buttons

| Class | Background | Text | Border | Usage |
|---|---|---|---|---|
| `.btn-primary` | `#24AE1D` | `#111111` | `#24AE1D` | Primary actions (Save, Submit, Find) |
| `.liatrio-btn-secondary` | transparent | `#24AE1D` | `#24AE1D` | Secondary actions |
| `.btn-danger` | `#dc3545` | `#fff` | `#dc3545` | Destructive actions (Delete) |

**Note:** `.btn-primary` has a `margin-top: 12px` override. Avoid using `.btn-primary` on non-button elements (like filter pills) to prevent layout issues.

### Filter Pills

Used on the Veterinarians page for specialty filtering.

| State | Background | Text | Border |
|---|---|---|---|
| Inactive | transparent | `#b3b3b3` | `#333333` |
| Hover | transparent | `#f8f9fa` | `#555555` |
| Active | transparent | `#24AE1D` | `#24AE1D` |
| Focus-visible | — | — | `2px solid #24AE1D` outline, `2px` offset |

- Shape: fully rounded (`border-radius: 9999px`)
- Contained in `.liatrio-filter-bar` (dark background, `#333` border, `8px` radius)
- Use `a.liatrio-filter-pill` class — never use `.btn` classes on pills

### Tables

- Header: `#111111` background, `#f8f9fa` text
- Rows: alternate between `#1a1f23` (odd) and `#1E2327` (even)
- Borders: `#333333`
- Links: `#89df00` (lime), hover: `#24AE1D` (green)
- Use `.table.table-striped.liatrio-table` class combination

### Forms

- Input background: `#111111`
- Input border: `#333333`, focus: `#24AE1D` with `0.2rem` green shadow
- Labels: `#f8f9fa`
- Placeholders: `#666666`
- Wrap in `.liatrio-form` for consistent styling
- Action buttons in `.liatrio-form-actions` (flex, 12px gap)

### Pagination

- Background: `#1E2327`
- Border radius: `8px`
- Padding: `12px 16px`
- Text: `#f8f9fa` for links, `#cccccc` for labels
- Icons: FontAwesome at `12px`
- Must preserve query parameters across page links

### Alerts

- Success: Bootstrap `.alert-success` (default green)
- Danger: Bootstrap `.alert-danger` (default red)
- Auto-hide after 3 seconds via JavaScript on owner details page

### Navigation Bar

- Background: `#111111` with `4px` green top border (`#24AE1D`)
- Links: uppercase, `14px`, `#cccccc` default, `#ffffff` + green background on hover
- Brand: logo (32x32) + text (16px, 600 weight, white)
- Language selector: Bootstrap dropdown at far right with globe icon

## Interaction States

| State | Pattern |
|---|---|
| Hover (links) | Color brightens or changes to green |
| Hover (buttons) | Background stays green (primary) or border brightens |
| Focus-visible | `2px solid #24AE1D` outline with `2px` offset |
| Active (nav) | Green background with white text |
| Active (filter pill) | Green border + green text |
| Disabled | Use Bootstrap defaults |

## Accessibility Requirements

- **Color contrast**: Minimum WCAG AA (4.5:1 for text, 3:1 for large text)
- **Focus indicators**: All interactive elements must have `:focus-visible` styles
- **Semantic HTML**: Use `<a>` for navigation, `<button>` for actions
- **Icon-only elements**: Must have `aria-label` or `aria-hidden="true"` if decorative
- **Form controls**: Must have associated `<label>` elements

## Responsive Behavior

- Navbar collapses on mobile with Bootstrap toggler
- Cards and tables are full-width on mobile
- Filter pills wrap with flexbox `flex-wrap: wrap`
- Buttons use `min-width: 140px` with flex layout for consistent sizing
