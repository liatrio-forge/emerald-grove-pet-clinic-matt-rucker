# 06 Tasks - Pet Deletion

Spec: [06-spec-pet-deletion.md](06-spec-pet-deletion.md)

## Relevant Files

- `src/main/java/org/springframework/samples/petclinic/owner/Owner.java` — Add `removePet()` method
- `src/main/java/org/springframework/samples/petclinic/owner/PetController.java` — Add POST delete endpoint
- `src/main/resources/templates/pets/createOrUpdatePetForm.html` — Add delete button for existing pets
- `src/main/resources/messages/messages*.properties` — i18n keys for delete button and confirmation
- `src/test/java/org/springframework/samples/petclinic/owner/PetControllerTests.java` — Add deletion tests
- `e2e-tests/tests/features/pet-deletion.spec.ts` — New Playwright E2E test
- `e2e-tests/tests/pages/pet-page.ts` — Playwright page object (check if exists, may need creation or update)

### Notes

- Unit tests use `@WebMvcTest(PetController.class)` with `@MockitoBean` for `OwnerRepository` and `PetTypeRepository`
- Pets cascade-delete visits via `@OneToMany(cascade = CascadeType.ALL)` — removing from Owner's list and saving handles everything
- Follow conventional commits, dual-loop TDD, Arrange-Act-Assert

## Tasks

### [x] 1.0 Pet Deletion with Confirmation

Add a delete button to the pet edit form that removes the pet (and its visits via cascade) after user confirmation via JavaScript `confirm()` dialog.

#### 1.0 Proof Artifact(s)

- JUnit: `PetControllerTests` — MockMvc tests for successful deletion with redirect and flash message, pet not found handling, and deletion of pet with visits
- Playwright: E2E test that creates a pet, navigates to edit, clicks delete, confirms, and verifies the pet is removed
- Screenshot: Pet edit form showing the red Delete Pet button

#### 1.0 Tasks

- [x] 1.1 **Outer loop — write failing acceptance tests** in `PetControllerTests`: (a) `POST /owners/{ownerId}/pets/{petId}/delete` redirects to owner details with flash message, (b) deleting a pet with visits succeeds (cascade), (c) deleting a non-existent pet returns error. All tests should fail.
- [x] 1.2 **Add `removePet()` method to `Owner.java`** — remove a pet by ID from the `pets` list, return boolean indicating success.
- [x] 1.3 **Add delete endpoint to `PetController`** — add `@PostMapping("/pets/{petId}/delete")` handler that calls `owner.removePet(petId)`, saves the owner, and redirects with a flash message. Handle pet-not-found case.
- [x] 1.4 **Update `createOrUpdatePetForm.html`** — add a red "Delete Pet" button (`btn-danger`) at the bottom of the form, visible only for existing pets (`th:unless="${pet['new']}"`). Use a hidden form with POST method. Add `onclick` JavaScript `confirm()` with pet name and visit count in the message.
- [x] 1.5 **Add i18n keys** — add `deletePet` and `petDeleted` keys to all `messages*.properties` files.
- [x] 1.6 **Inner loop — run tests, verify all pass** — run `./mvnw test` and confirm all new and existing tests pass.
- [x] 1.7 **Write Playwright E2E test** `pet-deletion.spec.ts` — create a pet for an owner, navigate to edit, click delete, accept confirmation, verify redirect to owner details and pet is no longer listed.
- [x] 1.8 **Capture proof artifacts** — save test output to `docs/specs/06-spec-pet-deletion/06-proofs/`.
