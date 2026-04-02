# 06 Questions Round 1 - Pet Deletion

## 1. Confirmation Method

- [x] (A) JavaScript confirm dialog (simplest — `confirm("Are you sure?")` before submitting)

## 2. Pets with Visits — Safety Behavior

- [x] (B) Allow deletion but with extra warning — confirmation message explicitly mentions visits will be deleted too

## 3. Delete Button Placement

- [x] (B) Only on the pet edit form page

## 4. Delete Button Style

- [x] (A) Red button/link (e.g., `btn-danger`) to clearly signal destructive action

## 5. HTTP Method for Deletion

- [x] (A) POST form submission (safest — prevents accidental deletion via URL, works without JavaScript)

## 6. Proof Artifacts

- [x] (A) Playwright E2E tests + JUnit controller tests (comprehensive)
