# Task 3.0 Proof Artifacts: Image Build and Push (ECR-Ready)

## Standalone Image Build

```bash
$ mise exec -- dagger -m dagger call build-image --source=.
✔ .buildImage(source: Address.directory: Directory!): Container!
Container@xxh3:8603f0525ef40855
```

Image built successfully using the project Containerfile.

## mise run ci Without Registry (Push Skipped)

```bash
$ mise run ci
=== Step 1: Build ===
Build: PASSED
=== Step 2: Test + Coverage ===
Coverage check passed (branch coverage meets threshold)
=== Step 3: Image Build ===
Image build: PASSED
=== Step 4: Push (skipped) ===
Skipping push: no registry configured
=== CI Pipeline: PASSED ===
```

Push step gracefully skipped when no `--registry` flag is provided.

## Push With Fake Registry (Auth Error Expected)

```bash
$ mise exec -- dagger -m dagger call run --source=. --registry=test.ecr.aws/fake
✘ Container.publish(address: "test.ecr.aws/fake:dae0d9c"): String!
! failed to export: failed to push test.ecr.aws/fake:dae0d9c:
  dial tcp: lookup test.ecr.aws: no such host
```

Key observations:

- Push path is wired up and attempts to publish
- Image correctly tagged with git SHA (`dae0d9c`)
- Fails with DNS/auth error for the fake registry (expected)
- Will succeed once Spec 13 provisions real ECR repository
