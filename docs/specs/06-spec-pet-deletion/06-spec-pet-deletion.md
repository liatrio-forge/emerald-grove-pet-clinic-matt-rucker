# 06-spec-pet-deletion

## Introduction/Overview

There is currently no way to remove a pet from an owner's record. This spec adds a delete action on the pet edit form page with a JavaScript confirmation dialog. Pets with visits trigger an extra warning that visits will also be deleted. The deletion uses a POST form submission for safety.

## Goals

- Allow users to delete a pet from an owner's record via the pet edit form
- Require explicit confirmation before deletion via JavaScript confirm dialog
- Warn users when deleting a pet that has existing visits (visits will be cascade-deleted)
- Ensure the pet and its visits no longer appear after deletion

## User Stories

- **As a receptionist**, I want to delete a pet that was added by mistake so that the owner's record stays accurate.
- **As a receptionist**, I want to be warned before deleting a pet with visits so that I don't accidentally lose visit history.

## Demoable Units of Work

### Unit 1: Pet Deletion with Confirmation

**Purpose:** Add a delete button to the pet edit form that removes the pet (and its visits via cascade) after user confirmation.

**Functional Requirements:**

- The system shall display a red "Delete Pet" button (`btn-danger`) on the pet edit form page (`createOrUpdatePetForm.html`), visible only for existing pets (not on the creation form)
- The system shall trigger a JavaScript `confirm()` dialog when the delete button is clicked
- The system shall include the pet's name in the confirmation message (e.g., "Are you sure you want to delete Max?")
- The system shall include a warning about visit deletion when the pet has visits (e.g., "This pet has 3 visit(s) that will also be deleted. Are you sure you want to delete Max?")
- The system shall submit a POST request to `/owners/{ownerId}/pets/{petId}/delete` when confirmed
- The system shall remove the pet from the owner's pet list and save the owner (JPA cascade deletes visits)
- The system shall redirect to the owner details page with a success flash message (e.g., "Pet has been deleted") after deletion
- The system shall not delete the pet if the user cancels the confirmation dialog
- The system shall add a `removePet(Integer petId)` method to the `Owner` entity
- The system shall handle the case where the pet ID does not exist (return error, don't crash)
- The system shall pass the pet's visit count to the template for the conditional warning message

**Proof Artifacts:**

- JUnit: `PetControllerTests` — MockMvc tests for successful deletion, deletion of pet with visits, pet not found error, and redirect with flash message
- Playwright: E2E test that creates a pet, navigates to edit, clicks delete, confirms, and verifies the pet is removed from the owner details page
- Screenshot: Pet edit form showing the red Delete Pet button

## Non-Goals (Out of Scope)

1. **Soft delete / archive**: Pets are permanently deleted, not archived or hidden
2. **Undo functionality**: No undo after deletion is confirmed
3. **Bulk deletion**: Only one pet at a time can be deleted
4. **Delete from owner details page directly**: Delete button is only on the pet edit form, not inline in the pet list
5. **Owner deletion**: This spec only covers pet deletion

## Design Considerations

- The "Delete Pet" button should be red (`btn-danger`) and placed at the bottom of the pet edit form, separated from the "Update Pet" button to prevent accidental clicks
- The button should only appear when editing an existing pet, not on the new pet form
- The confirmation dialog text should be context-aware (include pet name and visit count)
- Use the **frontend-design** and **web-design-guidelines** skills for UI implementation and review

## Repository Standards

- **Architecture**: Follows layered pattern — controller → repository → JPA entity
- **Data Access**: Pet deletion is handled by removing from Owner's pets list and saving via `OwnerRepository.save()` (cascade handles the rest)
- **Validation**: Pet ID existence check before deletion
- **Testing**: `@WebMvcTest` with `@MockitoBean`; Arrange-Act-Assert; Playwright E2E in `e2e-tests/`
- **Commits**: Conventional commits format `type(scope): description`
- **TDD**: Dual-loop TDD per project constitution
- **i18n**: Any new user-facing text must use message property keys

## Technical Considerations

- **Cascade deletion**: Pet has `@OneToMany(cascade = CascadeType.ALL)` with Visit, so removing a pet from the Owner's collection and saving the Owner will cascade-delete all visits for that pet
- **Owner.removePet()**: Need to add a method that removes a pet by ID from the `pets` list. The `getPets()` list is managed by JPA — removing from the list and saving the owner triggers the cascade
- **POST form**: The delete action uses a hidden form with POST method. The JavaScript `confirm()` runs `onclick` and submits the form only if confirmed. This avoids GET-based deletion which could be triggered by crawlers
- **Visit count for warning**: The controller already loads the pet via the owner. Pass `pet.getVisits().size()` to the template so the JavaScript can include the count in the confirmation message

## Security Considerations

- Using POST (not GET) prevents accidental deletion via URL prefetching or crawlers
- The `confirm()` dialog provides a client-side safety net, but the POST endpoint should still validate that the pet belongs to the specified owner

## Success Metrics

1. **Deletion accuracy**: Deleting a pet removes it and all its visits from the database
2. **Confirmation safety**: Users must explicitly confirm before deletion occurs
3. **Visit warning**: Users are warned when deleting a pet with visits, including the visit count
4. **No data leakage**: Deleted pet and visits do not appear anywhere after deletion
5. **Test coverage**: >90% line coverage for all new/modified code with both JUnit and Playwright tests

## Open Questions

No open questions at this time. All requirements have been clarified through the Q&A round.
