# 14 Questions Round 1 - CD Pipeline and Environment Lifecycle

## 1. Deploy Trigger

- [x] (A) Automatically on every merge to main — CI passes then deploy fires.

## 2. First Deploy Chicken-and-Egg

- [x] (A) Apply infra first (ECS service will fail — expected), then push first image via Dagger, then ECS picks it up. Document the bootstrap sequence.

## 3. Rollback Strategy

- [x] (A) No automated rollback — revert the commit on main and let CI redeploy the previous version. KISS.

## 4. Staging Cleanup

- [x] (A) Delete staging.tfvars. Single prod environment.

## 5. Teardown Confirmation

- [x] (C) Require a flag like `mise run teardown -- --confirm` to prevent accidental runs.

## 6. Should We Actually Apply the Infrastructure in This Spec?

- [x] (A) Yes — apply infra, push image, verify the app is running on the ALB URL. Full end-to-end proof.

## 7. Proof Artifacts

- [x] (A) Full end-to-end: tofu apply, mise run ci deploys, ALB URL returns the app, mise run teardown destroys everything.
