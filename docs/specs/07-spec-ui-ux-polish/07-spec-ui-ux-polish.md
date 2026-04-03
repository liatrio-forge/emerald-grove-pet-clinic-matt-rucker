# 07-spec-ui-ux-polish

## Introduction/Overview

The application lacks a way for users to switch the UI language despite having full i18n support with 9 language files and a configured `LocaleChangeInterceptor`. Additionally, navigating to a non-existent owner or pet ID shows a raw 500 error instead of a friendly 404 page. This spec adds a language selector dropdown to the global header and improves error handling to show user-friendly 404 pages with a link back to Find Owners.

## Goals

- Add a language selector dropdown to the navbar so users can switch UI language
- Support all 9 existing languages (EN, DE, ES, FA, KO, PT, RU, TR plus base English)
- Persist the selected language across navigation via the existing session-based locale resolver
- Return friendly 404 pages when accessing non-existent owners or pets
- Include a "Back to Find Owners" link on all 404 pages

## User Stories

- **As a non-English-speaking user**, I want to switch the UI to my language so that I can navigate the application comfortably.
- **As a user**, I want the language I select to persist as I navigate so that I don't have to re-select it on every page.
- **As a user**, I want to see a friendly message when I navigate to a non-existent owner or pet so that I understand what happened and can easily get back to a useful page.

## Demoable Units of Work

### Unit 1: Language Selector in Header (Issue #1)

**Purpose:** Add a dropdown language selector to the global header so users can switch the UI language on any page, using the existing i18n infrastructure.

**Functional Requirements:**

- The system shall display a language selector dropdown in the navbar, positioned after the last nav item (far right)
- The system shall list all 9 available languages with their native names (e.g., "English", "Deutsch", "Español", "فارسی", "한국어", "Português", "Русский", "Türkçe")
- The system shall switch the UI language when a language is selected by navigating to the current page with `?lang=xx` appended
- The system shall highlight or indicate the currently active language in the dropdown
- The system shall persist the selected language across page navigation via the existing `SessionLocaleResolver`
- The system shall display the current language name (or code) as the dropdown toggle text
- The system shall work on all pages (it is part of the global layout fragment)

**Proof Artifacts:**

- JUnit: Integration test verifying that `?lang=de` changes the page content to German
- Playwright: E2E test that opens the app, selects a language from the dropdown, verifies translated text appears, navigates to another page, and verifies the language persists
- Screenshot: Header showing the language dropdown open with all language options

### Unit 2: Friendly 404 for Missing Owner/Pet (Issue #10)

**Purpose:** Catch `IllegalArgumentException` from owner/pet lookups and return a proper 404 status so the existing `error.html` template renders a friendly message with a link back to Find Owners.

**Functional Requirements:**

- The system shall add a `@ControllerAdvice` class that catches `IllegalArgumentException` and sets the HTTP response status to 404
- The system shall render the existing `error.html` template with 404 status when an owner or pet is not found
- The system shall display the "The requested page was not found" message (already in error.html for 404 status)
- The system shall display a "Back to Find Owners" link on all 404 pages
- The system shall not expose stack traces or internal exception details to users
- The system shall continue to show the 500 error page for actual server errors (not mask them as 404)

**Proof Artifacts:**

- JUnit: MockMvc tests verifying that `/owners/9999` returns 404 status and `/owners/9999/pets/9999` returns 404 status
- Playwright: E2E test that navigates to a non-existent owner URL and verifies the friendly 404 message and "Back to Find Owners" link

## Non-Goals (Out of Scope)

1. **Adding new translations**: This spec adds the selector UI but does not translate the untranslated keys (filterAll, filterNone, etc.) in non-English files
2. **User account language preference**: Language is session-based, not persisted to a user profile
3. **Right-to-left (RTL) layout**: Farsi and other RTL languages will display in the selector but full RTL layout support is out of scope
4. **Custom 404 template**: Using the existing error.html with its 404 conditional, not creating a separate template
5. **Error handling for other exceptions**: Only `IllegalArgumentException` from entity lookups is caught; other exceptions continue to show as 500

## Design Considerations

- The language dropdown should use Bootstrap's dropdown component for consistency with the existing navbar style
- The dropdown toggle should show the current language name and a caret indicator
- The active language should have a visual indicator (e.g., bold, checkmark, or different color)
- The "Back to Find Owners" link on the 404 page should be styled as a prominent button or link below the error message
- Use the **frontend-design** and **web-design-guidelines** skills for UI implementation and review

## Repository Standards

- **Architecture**: `@ControllerAdvice` for cross-cutting error handling; layout changes in `fragments/layout.html`
- **i18n**: Existing `SessionLocaleResolver` + `LocaleChangeInterceptor` with `?lang=xx` param. Language selector just needs to construct URLs with this param.
- **Testing**: `@WebMvcTest` / `@SpringBootTest` with MockMvc; Playwright E2E in `e2e-tests/`
- **Commits**: Conventional commits format
- **TDD**: Dual-loop TDD per project constitution

## Technical Considerations

- **Language selector URL construction**: Each dropdown item links to the current page URL with `?lang=xx` appended. In Thymeleaf, use `@{${#httpServletRequest.requestURI}(lang='xx')}` or build the URL manually. The `LocaleChangeInterceptor` handles the rest.
- **`@ControllerAdvice` placement**: Place in the `system` package alongside `CrashController` since it's cross-cutting error handling, not domain-specific.
- **404 vs 500 distinction**: The `@ControllerAdvice` should catch `IllegalArgumentException` specifically and set status 404. The `@ResponseStatus(HttpStatus.NOT_FOUND)` annotation on the handler method achieves this. Spring Boot's default error handling then renders `error.html` with `${status} == 404`.
- **error.html modification**: Add a "Back to Find Owners" link inside the existing `th:if="${status == 404}"` block.

## Security Considerations

- The `@ControllerAdvice` should not expose the exception message to users (it may contain internal details like "Owner not found with id: 9999"). The error.html template uses its own i18n messages, not the exception message.
- The `?lang=xx` parameter is already sanitized by Spring's `LocaleChangeInterceptor` which only accepts valid locale codes.

## Success Metrics

1. **Language switching**: Selecting any of the 9 languages updates all UI text to that language
2. **Language persistence**: Selected language persists across at least 3 page navigations within the same session
3. **404 accuracy**: Navigating to `/owners/9999` or `/owners/1/pets/9999` returns HTTP 404 with friendly message
4. **No stack traces**: No internal exception details visible on the 404 page
5. **Test coverage**: >90% line coverage for all new/modified code

## Open Questions

No open questions at this time. All requirements have been clarified through the Q&A round.
